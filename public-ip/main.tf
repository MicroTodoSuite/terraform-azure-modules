# One Standard static IPv4 address. Terraform owns it; a Kubernetes Service
# only selects it by name and resource group. TenantReuse hashes the FQDN so no
# other tenant can claim it after the address is released.
resource "azurerm_public_ip" "this" {
  provider = azurerm.project

  name                    = var.public_ip.name
  resource_group_name     = var.public_ip.resource_group_name
  location                = var.public_ip.location
  sku                     = "Standard"
  allocation_method       = "Static"
  ip_version              = "IPv4"
  domain_name_label       = var.public_ip.domain_name_label
  domain_name_label_scope = "TenantReuse"
  tags                    = merge(local.tags, { Name = var.public_ip.name })
}
