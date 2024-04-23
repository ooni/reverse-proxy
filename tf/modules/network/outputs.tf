output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_subnet_public" {
  description = "The value of the public subnet associated to the VPC"
  value       = aws_subnet.public
}

output "vpc_subnet_private" {
  description = "The value of the private subnet associated to the VPC"
  value       = aws_subnet.private
}

output "vpc_subnet_cloudhsm" {
  description = "The value of the cloudhsm subnet associated to the VPC"
  value       = aws_subnet.cloudhsm
}
