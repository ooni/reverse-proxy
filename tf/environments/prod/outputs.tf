output "oonidataapi_alb_hostname" {
  value = module.ooni_dataapi.alb_dns_name
}

output "db_instance_endpoint" {
  value = module.postgresql.endpoint
}
