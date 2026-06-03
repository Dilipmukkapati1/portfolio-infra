resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

data "http" "current_client_ip" {
  count = var.allow_current_client_ip ? 1 : 0

  url = "https://api.ipify.org"

  request_headers = {
    Accept = "text/plain"
  }
}

locals {
  current_client_ip = var.allow_current_client_ip ? chomp(data.http.current_client_ip[0].response_body) : null
}

resource "azurerm_mssql_firewall_rule" "current_client" {
  count = var.allow_current_client_ip ? 1 : 0

  name             = "AllowCurrentClient"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = local.current_client_ip
  end_ip_address   = local.current_client_ip
}

resource "azurerm_mssql_firewall_rule" "additional_clients" {
  for_each = toset(var.additional_client_ips)

  name             = "AllowClient-${replace(each.value, ".", "-")}"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# Azure SQL free offer flags (useFreeLimit) require AzAPI until azurerm exposes them.
resource "azapi_resource" "databases" {
  for_each = toset(var.database_names)

  type      = "Microsoft.Sql/servers/databases@2023-08-01"
  name      = each.value
  parent_id = azurerm_mssql_server.this.id
  location  = var.location

  body = {
    properties = merge(
      {
        collation      = "SQL_Latin1_General_CP1_CI_AS"
        maxSizeBytes   = var.max_size_gb * 1024 * 1024 * 1024
        minCapacity    = var.min_capacity
        autoPauseDelay = var.auto_pause_delay_in_minutes
        readScale      = "Disabled"
      },
      var.use_free_offer ? {
        useFreeLimit                = true
        freeLimitExhaustionBehavior = var.free_limit_exhaustion_behavior
      } : {}
    )
    sku = {
      name     = "GP_S_Gen5"
      tier     = "GeneralPurpose"
      family   = "Gen5"
      capacity = 2
    }
  }

  tags = var.tags

  schema_validation_enabled = false
}
