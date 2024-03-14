output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_subnet" {
  description = "The value of the subnet associated to the VPC"
  value       = aws_subnet.main
}
