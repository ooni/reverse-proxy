variable "authorized_accounts" {
  description = "admin"
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}
