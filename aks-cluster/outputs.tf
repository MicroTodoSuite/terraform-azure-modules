# Outputs: granular IDs, names, URLs, and versions, each with a description
# (PC-IAC-007). No output carries a kubeconfig or a credential.
output "cluster_id" {
  description = "Resource ID of the cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL of the cluster, trusted by workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubernetes_version" {
  description = "Kubernetes version of the cluster."
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "api_server_authorized_cidrs" {
  description = "Addresses the API server admits, read from the cluster."
  value       = azurerm_kubernetes_cluster.this.api_server_access_profile[0].authorized_ip_ranges
}

output "node_resource_group_name" {
  description = "The AKS-managed resource group of the nodes."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
