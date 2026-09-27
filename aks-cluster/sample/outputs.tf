# Outputs that prove the sample works.
output "oidc_issuer_url" {
  description = "OIDC issuer URL of the sample cluster."
  value       = module.aks_cluster.oidc_issuer_url
}
