# The module's resources. Replace the example identity with the one service this module owns (PC-IAC-023).
resource "azurerm_user_assigned_identity" "this" {
  provider = azurerm.project

  name                = var.identity.name
  resource_group_name = var.identity.resource_group_name
  location            = var.identity.location
  tags                = local.tags
}
