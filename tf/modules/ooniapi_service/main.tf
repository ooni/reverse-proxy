locals {
  name = "ooniapi-service-${var.service_name}"
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_iam_role" "ooniapi_service_host" {
  name = "${local.name}-instance-role"

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

resource "aws_iam_instance_profile" "ooniapi_service_host" {
  name = local.name
  role = aws_iam_role.ooniapi_service_host.name

  tags = var.tags
}

resource "aws_iam_role_policy" "ooniapi_service_host" {
  name   = "${local.name}-instance-role-policy"
  role   = aws_iam_role.ooniapi_service_host.name
  policy = templatefile("${path.module}/templates/profile_policy.json", {})
}

resource "aws_security_group" "ooniapi_service_host" {
  description = "controls direct access to application instances"
  vpc_id      = var.vpc_id
  name        = "${local.name}-instance-sg"

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
      aws_security_group.ooniapi_service_web.id,
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



resource "aws_launch_template" "ooniapi_service" {
  name_prefix = local.name

  key_name      = var.key_name
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = var.instance_type

  user_data = base64encode(templatefile("${path.module}/templates/ecs-setup.sh", {
    ecs_cluster_name = var.ecs_cluster_name,
    ecs_cluster_tags = var.tags
  }))

  update_default_version               = true
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    name = aws_iam_instance_profile.ooniapi_service_host.name
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups = [
      aws_security_group.ooniapi_service_host.id,
    ]
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = var.volume_size
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

resource "aws_autoscaling_group" "ooniapi_service" {
  name_prefix         = local.name
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired

  launch_template {
    id      = aws_launch_template.ooniapi_service.id
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

resource "aws_security_group" "ooniapi_service_web" {
  description = "controls access to the applications ELB web endpoint"

  vpc_id = var.vpc_id
  name   = "${local.name}-web-sg"

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

resource "aws_iam_role" "ooniapi_service_task" {
  name = "${local.name}-task-role"

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

resource "aws_iam_role_policy" "ooniapi_service_task" {
  name = "${local.name}-task-role"
  role = aws_iam_role.ooniapi_service_task.name

  policy = templatefile("${path.module}/templates/profile_policy.json", {})
}

resource "aws_iam_role" "ooniapi_service_ecs" {
  name = "${local.name}-ecs-role"

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

resource "aws_iam_role_policy" "ooniapi_service_ecs" {
  name = "${local.name}-ecs-role"
  role = aws_iam_role.ooniapi_service_ecs.name

  policy = templatefile("${path.module}/templates/profile_policy.json", {})
}

resource "aws_cloudwatch_log_group" "ooniapi_service" {
  name = "ooni-ecs-group/${local.name}"
}

locals {
  secrets_spec = [
    for k, v in var.task_secrets : {
      name      = k,
      valueFrom = v
    }
  ]
}

resource "aws_ecs_task_definition" "ooniapi_service" {
  family = "${local.name}-td"
  container_definitions = templatefile("${path.module}/templates/task_definition.json", {
    image_url        = var.docker_image_url,
    container_name   = local.name,
    container_port   = 80,
    log_group_region = var.aws_region,
    log_group_name   = aws_cloudwatch_log_group.ooniapi_service.name,
    task_cpu         = var.task_cpu,
    task_memory      = var.task_memory,
    secrets_json     = jsonencode(local.secrets_spec)
  })

  execution_role_arn = aws_iam_role.ooniapi_service_task.arn
  tags               = var.tags
}

resource "aws_ecs_service" "ooniapi_service" {
  name            = local.name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.ooniapi_service.arn
  desired_count   = var.service_desired_count
  iam_role        = aws_iam_role.ooniapi_service_ecs.name

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_alb_target_group.ooniapi_service.id
    container_name   = local.name
    container_port   = "80"
  }

  depends_on = [
    aws_iam_role_policy.ooniapi_service_ecs,
    aws_alb_listener.ooniapi_service_http,
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  force_new_deployment = true

  tags = var.tags
}

resource "aws_alb_target_group" "ooniapi_service" {
  name     = local.name
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = var.tags
}

resource "aws_alb" "ooniapi_service" {
  name            = local.name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.ooniapi_service_web.id]

  tags = var.tags
}

resource "aws_alb_listener" "ooniapi_service_http" {
  load_balancer_arn = aws_alb.ooniapi_service.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ooniapi_service.id
    type             = "forward"
  }

  tags = var.tags
}

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = aws_alb.ooniapi_service.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ooniapi_service.arn

  default_action {
    target_group_arn = aws_alb_target_group.ooniapi_service.id
    type             = "forward"
  }

  tags = var.tags
}

resource "aws_route53_record" "ooniapi_service" {
  zone_id = var.dns_zone_ooni_io
  name    = "${var.service_name}.${var.stage}.ooni.io"
  type    = "A"

  alias {
    name                   = aws_alb.ooniapi_service.dns_name
    zone_id                = aws_alb.ooniapi_service.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "ooniapi_service" {
  domain_name       = "${var.service_name}.${var.stage}.ooni.io"
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ooniapi_service_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ooniapi_service.domain_validation_options : dvo.domain_name => {
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
  zone_id         = var.dns_zone_ooni_io
}

resource "aws_acm_certificate_validation" "ooniapi_service" {
  certificate_arn         = aws_acm_certificate.ooniapi_service.arn
  validation_record_fqdns = [for record in aws_route53_record.ooniapi_service_validation : record.fqdn]
  depends_on = [
    aws_route53_record.ooniapi_service
  ]
}
