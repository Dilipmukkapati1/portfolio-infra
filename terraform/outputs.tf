output "resource_group_name" {
  value = azurerm_resource_group.portfolio.name
}

output "cosmos_account_name" {
  value = module.cosmos_shared.account_name
}

output "cosmos_endpoint" {
  value = module.cosmos_shared.endpoint
}

output "cosmos_database_names" {
  value = local.cosmos_database_names
}

output "sql_server_name" {
  value = module.sql_shared.server_name
}

output "sql_server_fqdn" {
  value = module.sql_shared.fqdn
}

output "sql_database_names" {
  value = local.sql_database_names
}

output "storage_account_name" {
  value = module.storage_shared.name
}

output "key_vault_name" {
  value = module.keyvault_shared.name
}

output "log_analytics_workspace_name" {
  value = module.monitoring_shared.workspace_name
}

output "dev_function_app_name" {
  value = try(module.env_stack["dev"].function_app_name, null)
}

output "dev_function_app_url" {
  value = try(module.env_stack["dev"].function_app_url, null)
}

output "prod_function_app_name" {
  value = try(module.env_stack["prod"].function_app_name, null)
}

output "prod_function_app_url" {
  value = try(module.env_stack["prod"].function_app_url, null)
}

output "dev_static_web_app_name" {
  value = try(module.env_stack["dev"].static_web_app_name, null)
}

output "dev_static_web_app_hostname" {
  value = try(module.env_stack["dev"].static_web_app_hostname, null)
}

output "prod_static_web_app_name" {
  value = try(module.env_stack["prod"].static_web_app_name, null)
}

output "prod_static_web_app_hostname" {
  value = try(module.env_stack["prod"].static_web_app_hostname, null)
}

output "dev_function_app_principal_id" {
  value = try(module.env_stack["dev"].function_app_principal_id, null)
}

output "prod_function_app_principal_id" {
  value = try(module.env_stack["prod"].function_app_principal_id, null)
}

output "sql_admin_login" {
  value = module.sql_shared.admin_login
}

output "sql_admin_password" {
  value     = random_password.sql_admin.result
  sensitive = true
}

output "sql_database_dev" {
  value = one([for name in local.sql_database_names : name if endswith(name, "-dev")])
}
