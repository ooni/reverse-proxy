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

  content = templatefile("${path.module}/templates/ansible-inventory.tpl", {
    clickhouse_servers = [
      aws_route53_record.clickhouse_dns.name
    ]
  })
  filename = "${path.module}/ansible/inventory.ini"
}

resource "null_resource" "ansible_update_known_hosts" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "./scripts/update_known_hosts.sh"
    environment = {
      INVENTORY_FILE   = "ansible/inventory.ini"
      KNOWN_HOSTS_FILE = "ansible/known_hosts"
    }
  }
}

# Local variable definitions
locals {
  environment      = "production"
  name             = "ooni-tier1-${local.environment}"
  ecs_cluster_name = "ooni-ecs-cluster"
  dns_zone_ooni_nu = "Z035992527R8VEIX2UVO0" # ooni.nu hosted zone
  dns_zone_ooni_io = "Z02418652BOD91LFA5S9X" # ooni.io hosted zone

  tags = {
    Name       = local.name
    Repository = "https://github.com/ooni/devops"
  }
}

## AWS Setup

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

data "aws_availability_zones" "available" {}

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

# We care to ensure this data volume is not destroyed across re-applies. To do
# that you can either run first an apply with this commented out and then
# specify the data volume below. You can also just create a data volume with the
# appropriate tag manually and then edit the section below to indicate the name.
# If you do that, you will then have to manually also run:
# $ terraform state rm aws_ebs_volume.clickhouse_data_volume
#resource "aws_ebs_volume" "clickhouse_data_volume" {
#  availability_zone = aws_instance.clickhouse_server_prod_tier1.availability_zone
#  size              = 1024  # 1 TB
#  type              = "gp3" # SSD-based volume type, provides up to 16,000 IOPS and 1,000 MiB/s throughput
#  tags = merge(local.tags, {
#    Name = "ooni-tier1-prod-clickhouse-vol1"
#  })
#
#  lifecycle {
#    prevent_destroy = true
#  }
#}

data "aws_ebs_volume" "clickhouse_data_volume" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["ooni-tier1-prod-clickhouse-vol1"]
  }

  filter {
    name   = "availability-zone"
    values = [aws_instance.clickhouse_server_prod_tier1.availability_zone]
  }
}

resource "aws_volume_attachment" "clickhouse_data_volume_attachment" {
  device_name  = local.clickhouse_device_name
  volume_id    = data.aws_ebs_volume.clickhouse_data_volume.id
  instance_id  = aws_instance.clickhouse_server_prod_tier1.id
  force_detach = true
}

resource "aws_eip" "clickhouse_ip" {
  instance = aws_instance.clickhouse_server_prod_tier1.id

  tags = local.tags
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

### AWS RDS for PostgreSQL
resource "aws_security_group" "pg_sg" {
  description = "controls access to postgresql database"

  vpc_id = aws_vpc.main.id
  name   = "ooni-tier0-prod-postgres-sg"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_db_subnet_group" "main" {
  name       = "ooni-main"
  subnet_ids = [aws_subnet.main[0].id]

  tags = {
    Name = "Main"
  }
}

resource "aws_db_instance" "ooni_pg" {
  allocated_storage       = "10"
  max_allocated_storage   = "100"
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "16.1"
  instance_class          = "db.t3.micro"
  username                = "oonipg"
  password                = ""
  parameter_group_name    = "default.postgres16"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.pg_sg.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  publicly_accessible     = false

  # Enable deletion protection in production
  deletion_protection = true
}


### Compute for ECS

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_launch_template" "app" {
  name_prefix = "ooni-tier1-production-backend-lt"

  key_name      = var.key_name
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = "t2.micro"

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
      Name = "ooni-tier1-production-backend"
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

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
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
  container_name = "ooni_dataapi"
}

resource "aws_ecs_task_definition" "dataapi" {
  family = "ooni-dataapi-production-td"
  container_definitions = templatefile("${path.module}/templates/task_definition.json", {
    image_url        = "ooni/dataapi:${var.ooni_service_config.dataapi_version}",
    container_name   = local.container_name,
    container_port   = 80,
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

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = aws_alb.main.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.dataapi.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.dataapi.id
    type             = "forward"
  }

  tags = local.tags
}

# Route53

resource "aws_route53_record" "clickhouse_dns" {
  zone_id = local.dns_zone_ooni_nu
  name    = local.clickhouse_hostname
  type    = "A"
  ttl     = "300"
  records = [aws_eip.clickhouse_ip.public_ip]
}

resource "aws_route53_record" "postgres_dns" {
  zone_id = local.dns_zone_ooni_nu
  name    = "postgres.tier0.prod.ooni.nu"
  type    = "A"
  ttl     = "300"
  records = [aws_db_instance.ooni_pg.endpoint]
}

resource "aws_route53_record" "alb_dns" {
  zone_id = local.dns_zone_ooni_io
  name    = "dataapi.prod.ooni.io"
  type    = "A"

  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = true
  }
}

# ACM TLS

resource "aws_acm_certificate" "dataapi" {
  domain_name       = "dataapi.prod.ooni.io"
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dataapi_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.dataapi.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.dns_zone_ooni_io
}

resource "aws_acm_certificate_validation" "dataapi" {
  certificate_arn         = aws_acm_certificate.dataapi.arn
  validation_record_fqdns = [for record in aws_route53_record.dataapi_cert_validation : record.fqdn]
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "tf-ecs-group/ecs-agent"
}

resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-dataapi"
}
