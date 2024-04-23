variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "vpc_id" {
  description = "the id of the VPC to deploy the instance into"
}

variable "subnet_id" {
  description = "the id of the subnet for the HSM"
  type        = string
}

variable "subnet_cidr_block" {
  description = "the ids of the subnet of the subnets to deploy the instance into"
  type        = string
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}
