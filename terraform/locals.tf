locals {
  common_tags = {
    owner       = var.owner_email
    project     = "portfolio"
    cost-center = "personal"
    environment = "shared-rg"
    managed-by  = "terraform"
  }

  unique_suffix = random_string.suffix.result

  cosmos_containers = [
    "households",
    "members",
    "accounts",
    "transactions",
    "holdings",
    "taxProfiles",
    "scenarios",
    "projectionRuns",
    "integrationTokens",
    "syncState",
    "webhookEvents",
  ]

  cosmos_database_names = [for env in var.environments : "portfolio-${env}"]
  sql_database_names    = [for env in var.environments : "sqldb-${env}"]

  budget_notification_emails = length(var.cost_budget_emails) > 0 ? var.cost_budget_emails : [var.owner_email]
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false

  keepers = {
    resource_group = var.resource_group_name
  }
}
