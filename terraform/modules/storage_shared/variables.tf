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

variable "queue_names" {
  type = list(string)
}

variable "blob_container_names" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
