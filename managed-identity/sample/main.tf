# The identity sample: one call of the module, fed from locals.
module "identity" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  identity    = local.identity
  custom_role = null
}
