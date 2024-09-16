locals {
  name = "ooni-tier0-api-frontend"
}

resource "aws_alb" "ooniapi" {
  name            = local.name
  subnets         = var.subnet_ids
  security_groups = var.ooniapi_service_security_groups

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
  certificate_arn   = module.ooniapi_acm_certificate.certificate_arn

  default_action {
    target_group_arn = var.oonibackend_proxy_target_group_arn
    type             = "forward"
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "ooniapi_oonirun_rule" {
  listener_arn = aws_alb_listener.ooniapi_listener_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.ooniapi_oonirun_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/oonirun/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ooniapi_ooniauth_rule" {
  listener_arn = aws_alb_listener.ooniapi_listener_https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = var.ooniapi_ooniauth_target_group_arn
  }

  condition {
    path_pattern {
      values = [
        "/api/v2/ooniauth/*",
        "/api/v1/user_register",
        "/api/v1/user_login",
        "/api/v1/user_refresh_token",
        "/api/_/account_metadata",
      ]
    }
  }
}

resource "aws_lb_listener_rule" "ooniapi_ooniprobe_rule" {
  listener_arn = aws_alb_listener.ooniapi_listener_https.arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = var.ooniapi_ooniprobe_target_group_arn
  }

  condition {
    path_pattern {
      values = [
        "/api/v2/ooniprobe/*",
      ]
    }
  }
}

resource "aws_lb_listener_rule" "ooniapi_oonifindings_rule" {
  listener_arn = aws_alb_listener.ooniapi_listener_https.arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = var.ooniapi_oonifindings_target_group_arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/incidents/*"]
    }
  }
}

## DNS

module "ooniapi_acm_certificate" {
  source = "../ooniapi_acm_certificate"

  main_domain_name         = "api.${var.stage}.ooni.io"
  main_domain_name_zone_id = var.dns_zone_ooni_io

  alias_record_domain_name = aws_alb.ooniapi.dns_name
  alias_record_zone_id     = aws_alb.ooniapi.zone_id

  alternative_domains = var.alternative_domains

  tags = var.tags
}
