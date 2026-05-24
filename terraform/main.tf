data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "portfolio" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

resource "random_password" "sql_admin" {
  length  = 24
  special = true
}

module "cosmos_shared" {
  source = "./modules/cosmos_shared"

  resource_group_name = azurerm_resource_group.portfolio.name
  location            = var.location
  name_prefix         = var.name_prefix
  unique_suffix       = local.unique_suffix
  database_names      = local.cosmos_database_names
  container_names     = local.cosmos_containers
  enable_free_tier    = var.cosmos_enable_free_tier
  database_throughput = 400
  tags                = local.common_tags
}

module "sql_shared" {
  source = "./modules/sql_shared"

  resource_group_name            = azurerm_resource_group.portfolio.name
  location                       = var.location
  server_name                    = "${var.name_prefix}-sql-${local.unique_suffix}"
  database_names                 = local.sql_database_names
  admin_password                 = random_password.sql_admin.result
  max_size_gb                    = var.sql_max_size_gb
  use_free_offer                 = var.sql_use_free_offer
  free_limit_exhaustion_behavior = "AutoPause"
  tags                           = local.common_tags
}

module "storage_shared" {
  source = "./modules/storage_shared"

  resource_group_name = azurerm_resource_group.portfolio.name
  location            = var.location
  name_prefix         = var.name_prefix
  unique_suffix       = local.unique_suffix
  queue_names = [
    for env in var.environments : "portfolio-sync-${env}"
  ]
  blob_container_names = flatten([
    for env in var.environments : [
      "batch-packages-${env}",
      "function-releases-${env}",
    ]
  ])
  tags = local.common_tags
}

module "keyvault_shared" {
  source = "./modules/keyvault_shared"

  resource_group_name     = azurerm_resource_group.portfolio.name
  location                = var.location
  name_prefix             = var.name_prefix
  unique_suffix           = local.unique_suffix
  enable_purge_protection = var.keyvault_enable_purge_protection
  tags                    = local.common_tags
}

module "monitoring_shared" {
  source = "./modules/monitoring_shared"

  resource_group_name = azurerm_resource_group.portfolio.name
  location            = var.location
  name_prefix         = var.name_prefix
  unique_suffix       = local.unique_suffix
  tags                = local.common_tags
}

module "env_stack" {
  for_each = toset(var.environments)
  source   = "./modules/env_stack"

  environment                 = each.key
  name_prefix                 = var.name_prefix
  unique_suffix               = local.unique_suffix
  resource_group_name         = azurerm_resource_group.portfolio.name
  location                    = var.location
  log_analytics_workspace_id  = module.monitoring_shared.workspace_id
  storage_connection_string   = module.storage_shared.primary_connection_string
  storage_access_key          = module.storage_shared.primary_access_key
  storage_blob_endpoint       = module.storage_shared.primary_blob_endpoint
  function_releases_container = "function-releases-${each.key}"
  queue_name                  = "portfolio-sync-${each.key}"
  cosmos_endpoint             = module.cosmos_shared.endpoint
  cosmos_database_name        = "portfolio-${each.key}"
  cosmos_account_id           = module.cosmos_shared.account_id
  cosmos_account_name         = module.cosmos_shared.account_name
  sql_database_name           = "sqldb-${each.key}"
  sql_database_id             = module.sql_shared.database_ids["sqldb-${each.key}"]
  key_vault_id                = module.keyvault_shared.id
  key_vault_name              = module.keyvault_shared.name
  static_web_app_sku_tier     = var.static_web_app_sku_tier
  static_web_app_sku_size     = var.static_web_app_sku_size
  tags                        = merge(local.common_tags, { environment = each.key })
}

resource "azurerm_consumption_budget_subscription" "portfolio" {
  count = var.enable_cost_budget ? 1 : 0

  name            = "portfolio-monthly-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.cost_budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = local.budget_notification_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = local.budget_notification_emails
  }
}
