variable "environment" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "unique_suffix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "storage_connection_string" {
  type      = string
  sensitive = true
}

variable "storage_access_key" {
  type      = string
  sensitive = true
}

variable "storage_blob_endpoint" {
  type = string
}

variable "function_releases_container" {
  type = string
}

variable "queue_name" {
  type = string
}

variable "cosmos_endpoint" {
  type = string
}

variable "cosmos_database_name" {
  type = string
}

variable "cosmos_account_id" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "sql_database_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "static_web_app_sku_tier" {
  type    = string
  default = "Free"
}

variable "static_web_app_sku_size" {
  type    = string
  default = "Free"
}

variable "tags" {
  type    = map(string)
  default = {}
}
