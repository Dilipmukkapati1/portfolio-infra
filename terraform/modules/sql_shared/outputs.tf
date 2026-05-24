output "server_id" {
  value = azurerm_mssql_server.this.id
}

output "server_name" {
  value = azurerm_mssql_server.this.name
}

output "fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_ids" {
  value = { for k, db in azapi_resource.databases : k => db.id }
}

output "admin_login" {
  value = var.admin_login
}
