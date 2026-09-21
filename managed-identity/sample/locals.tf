# Name construction for the identity sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  identity = {
    name                = "${local.governance_prefix}-id-sample"
    resource_group_name = var.resource_group_name
    location            = var.location
  }
}
