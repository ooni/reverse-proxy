output "ooni_io_fqdn" {
  value = aws_route53_record.ooniapi_service.name
}

output "dns_name" {
  value = aws_alb.ooniapi_service.dns_name
}

output "ecs_service_name" {
  value = aws_ecs_service.ooniapi_service.name
}

output "alb_target_group_id" {
  value = aws_alb_target_group.ooniapi_service_mapped.id
}
