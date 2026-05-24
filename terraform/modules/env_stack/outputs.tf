output "function_app_name" {
  value = azurerm_function_app_flex_consumption.this.name
}

output "function_app_url" {
  value = "https://${azurerm_function_app_flex_consumption.this.name}.azurewebsites.net"
}

output "function_app_principal_id" {
  value = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

output "static_web_app_name" {
  value = azurerm_static_web_app.this.name
}

output "static_web_app_hostname" {
  value = azurerm_static_web_app.this.default_host_name
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}
