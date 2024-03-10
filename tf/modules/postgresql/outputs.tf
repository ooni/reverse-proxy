output "pg_address" {
  description = "The address of the postgres instance"
  value       = aws_db_instance.pg.address
}

output "pg_endpoint" {
  description = "The address of the postgres instance"
  value       = aws_db_instance.pg.endpoint
}

output "pg_db_name" {
  description = "The name of the postgres database"
  value       = aws_db_instance.pg.db_name
}

output "pg_username" {
  description = "The postgres username"
  value       = aws_db_instance.pg.db_name
}

output "pg_password" {
  sensitive   = true
  description = "The postgres password to login as pg_username into pg_db_name"
  value       = aws_secretsmanager_secret_version.pg_password.secret_string
}

output "secrets_manager_pg_password_id" {
  description = "The postgres password to login as pg_username into pg_db_name as a secrets_manager_id"
  value       = aws_secretsmanager_secret.pg_password.id
}
