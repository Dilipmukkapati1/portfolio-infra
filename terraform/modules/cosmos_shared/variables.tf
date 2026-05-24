variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "unique_suffix" {
  type = string
}

variable "database_names" {
  type = list(string)
}

variable "container_names" {
  type = list(string)
}

variable "enable_free_tier" {
  type    = bool
  default = true
}

variable "database_throughput" {
  type        = number
  description = "Shared RU/s per Cosmos SQL database (keep low for free tier; 2 DBs x 400 = 800)"
  default     = 400
}

variable "tags" {
  type    = map(string)
  default = {}
}
