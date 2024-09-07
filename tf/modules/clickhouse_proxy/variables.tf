variable "vpc_id" {
  description = "the id of the VPC to deploy the instance into"
}

variable "subnet_id" {
  description = "the id of the subnet to deploy the instance into"
}

variable "private_subnet_cidr" {
  description = "the cidr block of the private subnet to allow traffic from"
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}

variable "key_name" {
  description = "Name of AWS key pair"
}

variable "name" {
  description = "Name of the resources"
  default     = "ooni-clickhouse-proxy"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "stage" {
  default = "one of dev, stage, test, prod"
}

variable "dns_zone_ooni_io" {
  description = "id of the DNS zone for ooni_io"
}

variable "clickhouse_url" {
  description = "clickhouse url to proxy requests to"
  default = "backend-fsn.ooni.org" 
}

variable "clickhouse_port" {
  description = "clickhouse port for the backend"
}
