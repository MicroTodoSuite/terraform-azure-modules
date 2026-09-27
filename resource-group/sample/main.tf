# The resource-group sample: one call of the module, fed from locals.
module "resource_group" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client                   = var.client
  project                  = var.project
  environment              = var.environment
  expected_subscription_id = var.subscription_id
  resource_group           = local.resource_group
}
