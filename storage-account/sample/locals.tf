# Name construction for the storage-account sample.
locals {
  compact_prefix = "${var.client}${var.project}${var.environment}"

  storage_account = {
    name                = "${local.compact_prefix}stsample"
    resource_group_name = var.resource_group_name
    location            = var.location
    replication_type    = "LRS"
    retention_days      = 7
  }

  network_access = {
    allowed_ip_addresses = var.operator_addresses
    allowed_subnet_ids   = []
  }

  containers = {
    sample = {
      name = "sample"
    }
  }
}
