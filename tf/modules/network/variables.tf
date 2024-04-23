variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  type        = number
  default     = "2"
}

variable "aws_availability_zones_available" {
  description = "content of data.aws_availability_zones.available"
}

variable "vpc_main_cidr_block" {
  description = "the start address of the main VPC cidr"
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}

variable "enable_codesign_network" {
  description = "Enable codesign network"
  default     = false
  type        = bool
}
