# Name construction for the public-ip sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  public_ip = {
    name                = "${local.governance_prefix}-pip-sample"
    resource_group_name = var.resource_group_name
    location            = var.location
    domain_name_label   = "${local.governance_prefix}-sample"
  }
}
