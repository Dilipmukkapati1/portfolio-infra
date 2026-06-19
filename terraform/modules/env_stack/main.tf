locals {
  name_prefix_env   = "${var.name_prefix}-${var.environment}"
  function_app_name = "${local.name_prefix_env}-func-${var.unique_suffix}"
  hosting_plan_name = "${local.name_prefix_env}-plan"
  app_insights_name = "${local.name_prefix_env}-ai"
  swa_name          = "${local.name_prefix_env}-web-${var.unique_suffix}"

  storage_connection_string = var.storage_connection_string
  releases_container_url    = "${var.storage_blob_endpoint}${var.function_releases_container}"
}

resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id

  tags = var.tags
}

resource "azurerm_service_plan" "flex" {
  name                = local.hosting_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "FC1"

  tags = var.tags
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                = local.function_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.flex.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = local.releases_container_url
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = var.storage_access_key

  runtime_name           = "node"
  runtime_version        = "20"
  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.this.default_host_name}",
        "http://localhost:3000",
      ]
      support_credentials = false
    }
  }

  app_settings = {
    AzureWebJobsStorage                   = local.storage_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
    COSMOS_ENDPOINT                       = var.cosmos_endpoint
    COSMOS_DATABASE                       = var.cosmos_database_name
    KEY_VAULT_NAME                        = var.key_vault_name
    PORTFOLIO_QUEUE_NAME                  = var.queue_name
    AZURE_SQL_DATABASE                    = var.sql_database_name
    AZURE_SQL_CONNECTION_STRING           = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/${var.environment}-azure-sql-connection-string)"
    APP_ENV                               = var.environment == "prod" ? "production" : "development"
    DEFAULT_HOUSEHOLD_ID                  = var.environment == "prod" ? "prod-household" : "dev-household"
    AUTH_PASSWORD                         = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/${var.environment}-auth-password)"
    AUTH_SECRET                           = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/${var.environment}-auth-secret)"
    PRIVACY_JWT_SECRET                    = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/${var.environment}-privacy-jwt-secret)"
    OPENROUTER_API_KEY                    = "@Microsoft.KeyVault(SecretUri=https://${var.key_vault_name}.vault.azure.net/secrets/${var.environment}-openrouter-api-key)"
  }

  tags = var.tags
}

resource "azurerm_static_web_app" "this" {
  name                = local.swa_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_tier            = var.static_web_app_sku_tier
  sku_size            = var.static_web_app_sku_size

  tags = var.tags
}

# Key Vault Secrets Officer (read + set secrets for SimpleFIN connect, SnapTrade, etc.)
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

# Cosmos DB Built-in Data Contributor on database scope
data "azurerm_cosmosdb_sql_role_definition" "data_contributor" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = "00000000-0000-0000-0000-000000000002"
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data" {
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.data_contributor.id
  principal_id        = azurerm_function_app_flex_consumption.this.identity[0].principal_id
  scope               = "${var.cosmos_account_id}/dbs/${var.cosmos_database_name}"
}

# SQL DB Contributor on database scope
resource "azurerm_role_assignment" "sql_db_contributor" {
  scope                = var.sql_database_id
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}
