output "ooni_io_fqdn" {
  value = aws_route53_record.oonith_service.name
}

output "dns_name" {
  value = aws_alb.oonith_service.dns_name
}

output "ecs_service_name" {
  value = aws_ecs_service.oonith_service.name
}
