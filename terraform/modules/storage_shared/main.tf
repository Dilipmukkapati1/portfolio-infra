locals {
  storage_account_name = substr(replace("${var.name_prefix}st${var.unique_suffix}", "-", ""), 0, 24)
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_queue" "sync" {
  for_each = toset(var.queue_names)

  name               = each.value
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_storage_container" "blobs" {
  for_each = toset(var.blob_container_names)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
