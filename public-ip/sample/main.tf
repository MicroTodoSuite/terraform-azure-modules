# The public-ip sample: one call of the module, fed from locals.
module "public_ip" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment
  public_ip   = local.public_ip
}
