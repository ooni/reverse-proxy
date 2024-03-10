output "oonidevops_role_arn" {
  value = module.adm_iam_roles.oonidevops_role_arn
}

output "oonipg_pg_password" {
  value = module.postgresql.secrets_manager_pg_password_id
}

# output "oonidataapi_alb_hostname" {
#   value = module.ooni_dataapi.alb_dns_name
# }

# output "db_instance_endpoint" {
#   value = module.postgresql.endpoint
# }
