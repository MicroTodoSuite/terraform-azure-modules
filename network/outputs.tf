# Outputs: granular IDs and names, each with a description (PC-IAC-007).
output "virtual_network_id" {
  description = "Resource ID of the VNet."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the VNet."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Resource IDs of the subnets, by key."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "subnet_names" {
  description = "Names of the subnets, by key."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.name }
}
