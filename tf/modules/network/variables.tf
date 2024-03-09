variable "aws_access_key_id" {
  sensitive = true
}
variable "aws_secret_access_key" {
  sensitive = true
}

variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  type        = number
  default     = "2"
}

variable "vpc_main_cidr_block" {
  description = "the CIDR block of the default VPC"
  default     = "10.0.0.0/16"
}
