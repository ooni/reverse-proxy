output "address" {
  description = "The address of the postgres instance"
  value       = aws_db_instance.pg.address
}

output "endpoint" {
  description = "The address of the postgres instance"
  value       = aws_db_instance.pg.endpoint
}

