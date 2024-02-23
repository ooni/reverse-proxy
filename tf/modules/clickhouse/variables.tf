variable "datadog_api_key" {
  sensitive = true
}
variable "aws_access_key_id" {
  sensitive = true
}
variable "aws_secret_access_key" {
  sensitive = true
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "admin_cidr_ingress" {
  description = "CIDR to allow tcp/22 ingress to EC2 instance"
}

variable "aws_vpc_id" {
  description = "ID of the VPC to deploy into (eg. aws_vpc.main.id)"
}
variable "aws_subnet_id" {
  description = "ID of the VPC to deploy into (eg. aws_vpc.main.id)"
}

