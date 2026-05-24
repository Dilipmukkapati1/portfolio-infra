variable "subscription_id" {
  type        = string
  description = "Azure subscription ID for personal-portfolio-management"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "centralus"
}

variable "owner_email" {
  type        = string
  description = "Owner email for resource tags"
}

variable "name_prefix" {
  type        = string
  description = "Resource name prefix (ppm)"
  default     = "ppm"
}

variable "resource_group_name" {
  type        = string
  description = "Main resource group name"
  default     = "rg-portfolio"
}

variable "environments" {
  type        = list(string)
  description = "Logical environments deployed in the single RG"
  default     = ["dev", "prod"]
}

variable "keyvault_enable_purge_protection" {
  type        = bool
  description = "Enable Key Vault purge protection on the shared vault"
  default     = true
}

variable "cosmos_enable_free_tier" {
  type        = bool
  description = "Enable Cosmos DB lifetime free tier on the shared account"
  default     = true
}

variable "sql_use_free_offer" {
  type        = bool
  description = "Use Azure SQL Database free offer (GP serverless + use_free_limit)"
  default     = true
}

variable "sql_max_size_gb" {
  type        = number
  description = "Max size per SQL database (GB)"
  default     = 32
}

variable "static_web_app_sku_tier" {
  type        = string
  description = "Static Web App SKU tier"
  default     = "Free"
}

variable "static_web_app_sku_size" {
  type        = string
  description = "Static Web App SKU size"
  default     = "Free"
}

variable "enable_cost_budget" {
  type        = bool
  description = "Create subscription cost budget alert"
  default     = true
}

variable "cost_budget_amount" {
  type        = number
  description = "Monthly budget amount in USD for alerts"
  default     = 1
}

variable "cost_budget_emails" {
  type        = list(string)
  description = "Emails for budget alerts (defaults to owner_email)"
  default     = []
}

variable "budget_start_date" {
  type        = string
  description = "Budget period start (ISO 8601), e.g. 2026-05-01T00:00:00Z"
  default     = "2026-05-01T00:00:00Z"
}
