output "account_name" {
  value = azurerm_cosmosdb_account.this.name
}

output "account_id" {
  value = azurerm_cosmosdb_account.this.id
}

output "endpoint" {
  value = azurerm_cosmosdb_account.this.endpoint
}

output "database_ids" {
  value = { for k, db in azurerm_cosmosdb_sql_database.databases : k => db.id }
}
