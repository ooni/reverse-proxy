output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_subnet_public" {
  description = "The value of the subnet associated to the VPC"
  value       = aws_subnet.public
}

output "vpc_subnet_private" {
  description = "The value of the subnet associated to the VPC"
  value       = aws_subnet.private
}
