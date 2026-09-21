# One user-assigned managed identity. Its trust (federated credentials) and its
# permissions (role assignments) are granted by their own modules.
resource "azurerm_user_assigned_identity" "this" {
  provider = azurerm.project

  name                = var.identity.name
  resource_group_name = var.identity.resource_group_name
  location            = var.identity.location
  tags                = merge(local.tags, { Name = var.identity.name })
}
