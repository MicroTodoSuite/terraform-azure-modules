# Outputs that prove the sample works.
output "key_vault_url" {
  description = "Data-plane URL of the sample vault."
  value       = module.key_vault.key_vault_url
}
