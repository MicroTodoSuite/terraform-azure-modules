# Outputs: granular IDs, names, and endpoints, each with a description (PC-IAC-007).
output "public_ip_id" {
  description = "Resource ID of the address."
  value       = azurerm_public_ip.this.id
}

output "public_ip_name" {
  description = "Name of the address, for the service.beta.kubernetes.io/azure-pip-name annotation."
  value       = azurerm_public_ip.this.name
}

output "public_ip_resource_group_name" {
  description = "Resource group of the address, for the service.beta.kubernetes.io/azure-load-balancer-resource-group annotation."
  value       = azurerm_public_ip.this.resource_group_name
}

output "public_ip_endpoint" {
  description = "The IPv4 address."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_dns_name" {
  description = "Provider FQDN of the address."
  value       = azurerm_public_ip.this.fqdn
}
