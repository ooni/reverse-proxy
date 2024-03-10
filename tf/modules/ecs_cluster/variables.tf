variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "stage" {
  default = "one of dev, stage, test, prod"
}

variable "vpc_id" {
  description = "the id of the VPC to deploy the instance into"
}

variable "subnet_ids" {
  description = "the ids of the subnet of the subnets to deploy the instance into"
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}

variable "name" {
  description = "value of the ecs cluster name"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = 1
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = 4
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = 1
}

variable "admin_cidr_ingress" {
  default = "0.0.0.0/0"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_volume_size" {
  default = "5"
}
