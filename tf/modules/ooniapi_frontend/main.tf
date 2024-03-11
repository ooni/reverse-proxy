locals {
  name = "ooni-tier0-api-frontend"
}

resource "aws_security_group" "ooniapi" {
  description = "controls access to the application ELB"

  vpc_id = var.vpc_id
  name   = "${local.name}-sg"

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

resource "aws_alb" "ooniapi" {
  name            = local.name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.ooniapi.id]

  tags = var.tags
}

resource "aws_alb_listener" "ooniapi_listener_http" {
  load_balancer_arn = aws_alb.ooniapi.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

resource "aws_alb_listener" "ooniapi_listener_https" {
  load_balancer_arn = aws_alb.ooniapi.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.ooniapi.certificate_arn

  default_action {
    target_group_arn = var.oonibackend_proxy_target_group_arn
    type             = "forward"
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "oonidataapi_rule" {
  listener_arn = aws_alb_listener.ooniapi_listener_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.oonidataapi_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/*"]
    }
  }
}

## DNS

resource "aws_route53_record" "ooniapi" {
  zone_id = var.dns_zone_ooni_io
  name    = "api.${var.stage}.ooni.io"
  type    = "A"

  alias {
    name                   = aws_alb.ooniapi.dns_name
    zone_id                = aws_alb.ooniapi.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "ooniapi" {
  domain_name       = "api.${var.stage}.ooni.io"
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ooniapi_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ooniapi.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "ooniapi" {
  certificate_arn         = aws_acm_certificate.ooniapi.arn
  validation_record_fqdns = [for record in aws_route53_record.ooniapi_cert_validation : record.fqdn]
}
