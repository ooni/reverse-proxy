variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "az_count" {
  description = "The AWS region to create things in."
  default     = 1
}

variable "admin_cidr_ingress" {
  description = "CIDR to allow tcp/22 ingress to EC2 instance"
  default     = "0.0.0.0/0"
}
