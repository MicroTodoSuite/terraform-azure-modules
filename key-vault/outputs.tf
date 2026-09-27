# Outputs: granular IDs, names, and URLs, each with a description (PC-IAC-007).
output "key_vault_id" {
  description = "Resource ID of the vault, for role-assignment scopes."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_url" {
  description = "Data-plane URL of the vault."
  value       = azurerm_key_vault.this.vault_uri
}
