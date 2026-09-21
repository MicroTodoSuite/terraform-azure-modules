# Outputs: granular IDs, names, and endpoints, each with a description (PC-IAC-007).
output "container_registry_id" {
  description = "Resource ID of the registry, for role-assignment scopes."
  value       = azurerm_container_registry.this.id
}

output "container_registry_name" {
  description = "Name of the registry."
  value       = azurerm_container_registry.this.name
}

output "container_registry_endpoint" {
  description = "Login server of the registry."
  value       = azurerm_container_registry.this.login_server
}
