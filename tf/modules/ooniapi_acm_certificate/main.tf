resource "aws_route53_record" "main" {
  name    = var.main_domain_name
  zone_id = var.main_domain_name_zone_id
  type    = "A"

  alias {
    name                   = var.alias_record_domain_name
    zone_id                = var.alias_record_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alt" {
  for_each = var.alternative_domains

  name    = each.key
  zone_id = each.value
  type    = "A"

  alias {
    name                   = var.alias_record_domain_name
    zone_id                = var.alias_record_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.main_domain_name
  validation_method = "DNS"

  tags = var.tags

  subject_alternative_names = [for domain_name, zone_id in var.alternative_domains : domain_name]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
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
  zone_id         = var.main_domain_name_zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
