resource "aws_cloudwatch_log_group" "app" {
  name = "tf-ecs-group/app-dataapi"
}

### Compute for ECS

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_iam_instance_profile" "app" {
  name = "tf-ecs-instprofile"
  role = aws_iam_role.app_instance.name

  tags = var.tags
}

resource "aws_iam_role" "app_instance" {
  name = "tf-ecs-ooni-instance-role"

  tags = var.tags

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

resource "aws_launch_template" "app" {
  name_prefix = "ooni-tier1-production-backend-lt"

  key_name      = var.key_name
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = "t2.micro"

  user_data = base64encode(templatefile("${path.module}/templates/ecs-setup.sh", {
    ecs_cluster_name = var.ecs_cluster_name,
    ecs_cluster_tags = var.tags
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
      aws_security_group.instance.id,
    ]
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = "5"
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
  name_prefix         = "ooni-ecs-asg"
  vpc_zone_identifier = var.subnet_ids
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

resource "aws_security_group" "web" {
  description = "controls access to the application ELB"

  vpc_id = var.vpc_id
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

  tags = var.tags
}

resource "aws_security_group" "instance" {
  description = "controls direct access to application instances"
  vpc_id      = var.vpc_id
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
      aws_security_group.web.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


resource "aws_ecs_task_definition" "oonidataapi" {
  family = "ooni-dataapi-production-td"
  container_definitions = templatefile("${path.module}/templates/task_definition.json", {
    # Image URL is updated via code build and code pipeline
    image_url        = "ooni/dataapi:latest",
    container_name   = var.container_name,
    container_port   = 80,
    log_group_region = var.aws_region,
    log_group_name   = aws_cloudwatch_log_group.app.name,
  })

  execution_role_arn = aws_iam_role.ecs_task.arn
  tags               = var.tags
}

resource "aws_ecs_service" "oonidataapi" {
  name            = "ooni-ecs-dataapi-production"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.oonidataapi.arn
  desired_count   = var.service_desired
  iam_role        = aws_iam_role.ecs_service.name

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_alb_target_group.oonidataapi.id
    container_name   = var.container_name
    container_port   = "80"
  }

  depends_on = [
    aws_iam_role_policy.ecs_service,
    aws_alb_listener.front_end,
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  force_new_deployment = true

  tags = var.tags
}

## IAM

resource "aws_iam_role" "ecs_task" {
  name = "ooni_ecs_task_role"

  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task" {
  name = "ooni_ecs_task_policy"
  role = aws_iam_role.ecs_task.name

  policy = templatefile("${path.module}/templates/instance_profile_policy.json", {})
}

resource "aws_iam_role" "ecs_service" {
  name = "ooni_ecs_role"

  tags = var.tags

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

  policy = templatefile("${path.module}/templates/instance_profile_policy.json", {})
}

resource "aws_iam_role_policy" "instance" {
  name   = "TfEcsOONIInstanceRole"
  role   = aws_iam_role.app_instance.name
  policy = templatefile("${path.module}/templates/instance_profile_policy.json", {})
}


## ALB

resource "aws_alb_target_group" "oonidataapi" {
  name     = "ooni-tier1-oonidataapi"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = var.tags
}

resource "aws_alb" "oonidataapi" {
  name            = "ooni-tier1-oonidataapi"
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.web.id]

  tags = var.tags
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.oonidataapi.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.oonidataapi.id
    type             = "forward"
  }

  tags = var.tags
}

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = aws_alb.oonidataapi.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.oonidataapi.id
    type             = "forward"
  }

  tags = var.tags
}

