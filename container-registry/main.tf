# One Premium container registry. The admin user and anonymous pull stay
# disabled, so every pull and push authenticates with an Entra identity
# (AcrPull, AcrPush), and the firewall denies by default: only the named
# addresses and trusted Azure services reach it.
resource "azurerm_container_registry" "this" {
  provider = azurerm.project

  name                   = var.container_registry.name
  resource_group_name    = var.container_registry.resource_group_name
  location               = var.container_registry.location
  sku                    = var.container_registry.sku
  admin_enabled          = false
  anonymous_pull_enabled = false

  # The firewall needs the public endpoint; it admits only the named addresses.
  public_network_access_enabled = true
  network_rule_bypass_option    = "AzureServices"

  network_rule_set {
    default_action = "Deny"
    ip_rule        = [for cidr in var.network_access.allowed_ip_cidrs : { action = "Allow", ip_range = cidr }]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.tags, { Name = var.container_registry.name })
}
