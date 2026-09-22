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

output "federated_credential_ids" {
  description = "Resource IDs of the federated credentials, by key."
  value       = { for key, credential in azurerm_federated_identity_credential.this : key => credential.id }
}

output "role_assignment_ids" {
  description = "Resource IDs of the role assignments, by key."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.id }
}
