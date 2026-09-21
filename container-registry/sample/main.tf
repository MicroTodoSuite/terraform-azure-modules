# The container-registry sample: one call of the module, fed from locals.
module "container_registry" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client             = var.client
  project            = var.project
  environment        = var.environment
  container_registry = local.container_registry
}
