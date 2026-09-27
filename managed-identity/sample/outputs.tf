# Outputs that prove the sample works.
output "identity_client_id" {
  description = "Client ID of the sample identity."
  value       = module.identity.identity_client_id
}
