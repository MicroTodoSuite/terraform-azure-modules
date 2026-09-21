# Outputs that prove the sample works.
output "storage_account_name" {
  description = "Name of the sample account."
  value       = module.storage_account.storage_account_name
}
