# Name construction for the resource-group sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  resource_group = {
    name     = "${local.governance_prefix}-rg-sample"
    location = var.location
  }
}
