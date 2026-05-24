data "azurerm_client_config" "current" {}

locals {
  key_vault_name = substr("${var.name_prefix}-kv-${var.unique_suffix}", 0, 24)
}

resource "azurerm_key_vault" "this" {
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = var.enable_purge_protection

  rbac_authorization_enabled = true

  tags = var.tags
}
