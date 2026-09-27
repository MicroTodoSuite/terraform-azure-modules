# Outputs: granular IDs and names, each with a description (PC-IAC-007).
output "resource_group_id" {
  description = "Resource ID of the resource group, for role-assignment scopes."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}
