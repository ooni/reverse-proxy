variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}

variable "email_address" {
  description = "environment name"
}
