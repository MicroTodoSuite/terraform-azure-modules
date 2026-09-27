# Name construction for the key-vault sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  key_vault = {
    name                       = "${local.governance_prefix}-kv-sample"
    resource_group_name        = var.resource_group_name
    location                   = var.location
    soft_delete_retention_days = 7
  }

  network_access = {
    allowed_ip_cidrs   = var.operator_cidrs
    allowed_subnet_ids = []
  }
}
