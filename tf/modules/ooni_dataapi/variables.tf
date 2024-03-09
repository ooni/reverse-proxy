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

variable "key_name" {
  description = "Name of AWS key pair"
  default     = "ooni-devops-prod"
}

variable "name" {
  default = "name of the postgresql instance"
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

variable "ecs_cluster_name" {
  description = "value of the ecs cluster name"
}

variable "ecs_cluster_id" {
  description = "value of the ecs cluster id"
}

variable "service_desired" {
  description = "Desired numbers of instances in the ecs service"
  default     = 2
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

variable "container_name" {
  default = "ooni_dataapi"
}

variable "admin_cidr_ingress" {
  default = "0.0.0.0/0"
}

variable "certificate_arn" {
  description = "ARN of the certificate to use for the ELB"
}
