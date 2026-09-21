# One container registry. The admin user and anonymous pull stay disabled, so
# every pull and push authenticates with an Entra identity (AcrPull, AcrPush).
resource "azurerm_container_registry" "this" {
  provider = azurerm.project

  name                   = var.container_registry.name
  resource_group_name    = var.container_registry.resource_group_name
  location               = var.container_registry.location
  sku                    = var.container_registry.sku
  admin_enabled          = false
  anonymous_pull_enabled = false
  tags                   = merge(local.tags, { Name = var.container_registry.name })
}
