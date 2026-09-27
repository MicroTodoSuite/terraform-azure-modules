# Name construction for the network sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  virtual_network = {
    name                = "${local.governance_prefix}-vnet-sample"
    resource_group_name = var.resource_group_name
    location            = var.location
    address_space       = var.address_space
  }

  subnets = {
    nodes = {
      name              = "${local.governance_prefix}-snet-sample"
      address_prefix    = var.node_subnet_prefix
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }
}
