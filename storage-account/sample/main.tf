# The storage-account sample: one call of the module, fed from locals.
module "storage_account" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  storage_account = local.storage_account
  network_access  = local.network_access
  containers      = local.containers
}
