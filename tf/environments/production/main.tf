# Store terraform state in s3
terraform {
  backend "s3" {
    region  = "eu-central-1"
    bucket  = "ooni-production-terraform-state"
    key     = "terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "ooni-production-terraform-state-lock"
  }
}

# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "1.4.0"
  namespace  = "ooni"
  stage      = "production"
  name       = "terraform"
  attributes = ["state"]

  #terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

## Ansible inventory

resource "local_file" "ansible_inventory" {
  depends_on = [
    aws_route53_record.clickhouse_dns
  ]

  content  = templatefile("${path.module}/templates/ansible-inventory.tpl", {
    clickhouse_servers = [
      local.clickhouse_hostname
    ]
  })
  filename = "${path.module}/ansible/inventory.ini"
}

resource "null_resource" "ansible_update_known_hosts" {
  depends_on = [ local_file.ansible_inventory ]

  provisioner "local-exec" {
    command = "./scripts/update_known_hosts.sh"
    environment = {
      INVENTORY_FILE = "ansible/inventory.ini"
      KNOWN_HOSTS_FILE = "ansible/known_hosts"
    }
  }
}

## AWS Setup

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

data "aws_availability_zones" "available" {}

locals {
  environment      = "production"
  name             = "ooni-tier1-${local.environment}"
  ecs_cluster_name = "ooni-ecs-cluster"

  tags = {
    Name       = local.name
    Repository = "https://github.com/ooni/devops"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.main[*].id, count.index)
  route_table_id = aws_route_table.r.id
}


### EC2

locals {
  clickhouse_hostname    = "clickhouse.tier1.prod.ooni.nu"
  clickhouse_device_name = "/dev/sdf"
}

data "aws_ami" "debian_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"] # Debian's official AWS account ID
}

resource "aws_instance" "clickhouse_server_prod_tier1" {
  ami           = data.aws_ami.debian_ami.id
  instance_type = "r5.xlarge"
  key_name      = var.key_name

  associate_public_ip_address = true

  subnet_id              = aws_subnet.main[0].id
  vpc_security_group_ids = [aws_security_group.clickhouse_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = templatefile("${path.module}/templates/clickhouse-setup.sh", {
    datadog_api_key = var.datadog_api_key,
    hostname        = local.clickhouse_hostname,
    device_name     = local.clickhouse_device_name
  })

  tags = merge(
    local.tags,
    {
      Name = "clickhouse-${local.tags["Name"]}"
    }
  )
}

resource "aws_ebs_volume" "clickhouse_data_volume" {
  availability_zone = aws_instance.clickhouse_server_prod_tier1.availability_zone
  size              = 1024  # 1 TB
  type              = "gp3" # SSD-based volume type, provides up to 16,000 IOPS and 1,000 MiB/s throughput
  tags              = local.tags
}

resource "aws_volume_attachment" "clickhouse_data_volume_attachment" {
  device_name  = local.clickhouse_device_name
  volume_id    = aws_ebs_volume.clickhouse_data_volume.id
  instance_id  = aws_instance.clickhouse_server_prod_tier1.id
  force_detach = true
}

resource "aws_eip" "clickhouse_ip" {
  instance = aws_instance.clickhouse_server_prod_tier1.id

  tags = local.tags
}

resource "aws_route53_record" "clickhouse_dns" {
  zone_id = "Z035992527R8VEIX2UVO0" # ooni.nu hosted zone
  name    = local.clickhouse_hostname
  type    = "A"
  ttl     = "300"
  records = [aws_eip.clickhouse_ip.public_ip]
}

resource "aws_security_group" "clickhouse_sg" {
  name        = "clickhouse_sg"
  description = "Allow Clickhouse traffic"

  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      var.admin_cidr_ingress,
    ]
  }

  ingress {
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["93.65.174.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

### Compute for ECS

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_launch_template" "app" {
  name_prefix = "ooni-tier1-production-backend-lt"

  key_name      = var.key_name
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/templates/ecs-setup.sh", {
    ecs_cluster_name = local.ecs_cluster_name,
    ecs_cluster_tags = local.tags,
    datadog_api_key  = var.datadog_api_key,
  }))

  update_default_version               = true
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      aws_security_group.instance_sg.id,
    ]
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name : "ooni-tier1-production-backend"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "ooni-tier1-production-backend-asg"
  vpc_zone_identifier = aws_subnet.main[*].id
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["tag"]
  }

}


### Security

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = aws_vpc.main.id
  name   = "tf-ecs-lbsg"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = local.tags
}

resource "aws_security_group" "instance_sg" {
  description = "controls direct access to application instances"
  vpc_id      = aws_vpc.main.id
  name        = "tf-ecs-instsg"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      var.admin_cidr_ingress,
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 61000

    security_groups = [
      aws_security_group.lb_sg.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

## ECS

resource "aws_ecs_cluster" "main" {
  name = local.ecs_cluster_name
  tags = local.tags
}


locals {
  container_image = "ooni/dataapi:latest"
  container_name  = "ooni_dataapi"
  container_port  = 80
}

resource "aws_ecs_task_definition" "dataapi" {
  family = "ooni-dataapi-production-td"
  container_definitions = templatefile("${path.module}/templates/task_definition.json", {
    image_url        = local.container_image,
    container_name   = local.container_name,
    container_port   = local.container_port,
    log_group_region = var.aws_region,
    log_group_name   = aws_cloudwatch_log_group.app.name
  })

  tags = local.tags
}

resource "aws_ecs_service" "dataapi" {
  name            = "ooni-ecs-dataapi-production"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.dataapi.arn
  desired_count   = var.service_desired
  iam_role        = aws_iam_role.ecs_service.name

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_alb_target_group.dataapi.id
    container_name   = local.container_name
    container_port   = "80"
  }

  depends_on = [
    aws_iam_role_policy.ecs_service,
    aws_alb_listener.front_end,
  ]

  force_new_deployment = true

  triggers = {
    # see: https://github.com/hashicorp/terraform-provider-aws/issues/28070#issuecomment-1824780763
    redeployment = plantimestamp()
  }

  tags = local.tags
}

## IAM

resource "aws_iam_role" "ecs_service" {
  name = "ooni_ecs_role"

  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "ooni_ecs_policy"
  role = aws_iam_role.ecs_service.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app" {
  name = "tf-ecs-instprofile"
  role = aws_iam_role.app_instance.name

  tags = local.tags
}

resource "aws_iam_role" "app_instance" {
  name = "tf-ecs-ooni-instance-role"

  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance" {
  name = "TfEcsOONIInstanceRole"
  role = aws_iam_role.app_instance.name
  policy = templatefile("${path.module}/templates/instance_profile_policy.json", {
    app_log_group_arn = aws_cloudwatch_log_group.app.arn,
    ecs_log_group_arn = aws_cloudwatch_log_group.ecs.arn
  })

}

## ALB

resource "aws_alb_target_group" "dataapi" {
  name     = "ooni-ecs-dataapi"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  tags = local.tags
}

resource "aws_alb" "main" {
  name            = "ooni-alb-ecs"
  subnets         = aws_subnet.main[*].id
  security_groups = [aws_security_group.lb_sg.id]

  tags = local.tags
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.dataapi.id
    type             = "forward"
  }

  tags = local.tags
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-dataapi"
}
