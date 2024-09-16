variable "main_domain_name" {
  type        = string
  description = "main domain_name"
}

variable "main_domain_name_zone_id" {
  type        = string
  description = "main domain_name zone_id"
}

variable "alternative_domains" {
  type        = map(string)
  description = "domain_name to zone_id map"
  default     = {}
}

variable "alias_record_domain_name" {
  type        = string
  description = "domain name the record alias points to"
}

variable "alias_record_zone_id" {
  type        = string
  description = "zone_id for the alias record"
}

variable "tags" {
  description = "tags to apply to the resources"
  default     = {}
  type        = map(string)
}
