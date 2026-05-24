locals {
  log_analytics_name = "${var.name_prefix}-logs-${var.unique_suffix}"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}
