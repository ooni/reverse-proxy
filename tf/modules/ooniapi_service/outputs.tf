output "ooni_io_fqdn" {
  value = aws_route53_record.ooniapi_service.name
}

output "dns_name" {
  value = aws_alb.ooniapi_service.dns_name
}
