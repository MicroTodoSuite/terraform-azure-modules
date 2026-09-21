# One VNet and its subnets. Every subnet is private: default outbound access
# is off, so nodes leave only through an explicit path such as a Standard Load
# Balancer, and service endpoints let the services behind them deny public
# access.
resource "azurerm_virtual_network" "this" {
  provider = azurerm.project

  name                = var.virtual_network.name
  resource_group_name = var.virtual_network.resource_group_name
  location            = var.virtual_network.location
  address_space       = [var.virtual_network.address_space]
  tags                = merge(local.tags, { Name = var.virtual_network.name })
}

resource "azurerm_subnet" "this" {
  provider = azurerm.project
  for_each = var.subnets

  name                            = each.value.name
  resource_group_name             = var.virtual_network.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [each.value.address_prefix]
  default_outbound_access_enabled = false

  dynamic "service_endpoint" {
    for_each = toset(each.value.service_endpoints)

    content {
      service = service_endpoint.value
    }
  }
}
