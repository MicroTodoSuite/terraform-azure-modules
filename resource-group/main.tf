# One resource group. Its precondition stops any plan whose authenticated
# client is outside the approved subscription, before anything else is planned
# into the group.
resource "azurerm_resource_group" "this" {
  provider = azurerm.project

  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = merge(local.tags, { Name = var.resource_group.name })

  lifecycle {
    precondition {
      condition     = data.azurerm_client_config.current.subscription_id == var.expected_subscription_id
      error_message = "The authenticated Azure client is not in the approved subscription; nothing is planned against another subscription."
    }
  }
}
