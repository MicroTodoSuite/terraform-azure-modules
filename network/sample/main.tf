# The network sample: one call of the module, fed from locals.
module "network" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  virtual_network = local.virtual_network
  reserved_cidrs  = var.reserved_cidrs
  subnets         = local.subnets
}
