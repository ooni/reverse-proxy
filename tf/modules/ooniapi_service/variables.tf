variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "service_name" {
  description = "short service name. will become the first part of the fqdn eg. <service_name>.prod.ooni.io"
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

variable "ecs_cluster_name" {
  description = "value of the ecs cluster name"
}

variable "ecs_cluster_id" {
  description = "value of the ecs cluster id"
}

variable "service_desired_count" {
  description = "Desired numbers of instances in the ecs service"
  default     = 1
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

variable "volume_size" {
  default = "5"
}

variable "task_cpu" {
  default     = 256
  description = "https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size"
}

variable "task_memory" {
  default     = 512
  description = "https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size"
}

variable "dns_zone_ooni_io" {
  description = "id of the DNS zone for ooni_io"
}

variable "docker_image_url" {
  description = "the url to the docker image"
}

variable "task_secrets" {
  default = {}
  type    = map(string)
}
