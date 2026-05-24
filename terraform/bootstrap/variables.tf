variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "Region for state storage"
}

variable "state_resource_group_name" {
  type        = string
  default     = "rg-portfolio-tfstate"
  description = "Resource group for Terraform remote state"
}
