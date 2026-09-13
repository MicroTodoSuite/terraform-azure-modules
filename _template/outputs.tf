# Outputs: granular IDs and names, each with a description (PC-IAC-007).
output "identity_id" {
  description = "Resource ID of the identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "identity_client_id" {
  description = "Client ID of the identity, for workload identity federation."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "identity_principal_id" {
  description = "Principal ID of the identity's service principal, for role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "identity_name" {
  description = "Name of the identity."
  value       = azurerm_user_assigned_identity.this.name
}
