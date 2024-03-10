output "ooniapi_ooni_io_fqdn" {
  value = aws_route53_record.ooniapi.name
}

output "ooniapi_dns_name" {
  value = aws_alb.ooniapi.dns_name
}
