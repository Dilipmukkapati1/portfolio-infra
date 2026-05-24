locals {
  account_name = substr(replace("${var.name_prefix}cosmos${var.unique_suffix}", "-", ""), 0, 44)
}

resource "azurerm_cosmosdb_account" "this" {
  name                = local.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  free_tier_enabled = var.enable_free_tier

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "databases" {
  for_each = toset(var.database_names)

  name                = each.value
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name

  # Shared throughput per database (free tier: 1000 RU/s total across account)
  throughput = var.database_throughput
}

# Cosmos databases are eventually consistent immediately after create.
resource "time_sleep" "wait_for_databases" {
  depends_on = [azurerm_cosmosdb_sql_database.databases]

  create_duration = "60s"
}

resource "azurerm_cosmosdb_sql_container" "containers" {
  for_each = {
    for pair in setproduct(var.database_names, var.container_names) :
    "${pair[0]}.${pair[1]}" => {
      database  = pair[0]
      container = pair[1]
    }
  }

  name                = each.value.container
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = each.value.database

  partition_key_paths = ["/householdId"]

  depends_on = [time_sleep.wait_for_databases]
}
