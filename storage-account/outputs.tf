# Outputs: granular IDs and names, each with a description (PC-IAC-007).
output "storage_account_id" {
  description = "Resource ID of the account, for role-assignment scopes."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the account."
  value       = azurerm_storage_account.this.name
}

output "container_names" {
  description = "Names of the containers, by key."
  value       = { for key, container in azurerm_storage_container.this : key => container.name }
}
