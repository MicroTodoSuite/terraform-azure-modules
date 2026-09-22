# The key-vault sample: one call of the module, fed from locals.
module "key_vault" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client         = var.client
  project        = var.project
  environment    = var.environment
  key_vault      = local.key_vault
  network_access = local.network_access
}
