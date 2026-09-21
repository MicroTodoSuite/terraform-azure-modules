# Name construction for the container-registry sample.
locals {
  compact_prefix = "${var.client}${var.project}${var.environment}"

  container_registry = {
    name                = "${local.compact_prefix}acrsample"
    resource_group_name = var.resource_group_name
    location            = var.location
    sku                 = "Premium"
  }

  network_access = {
    allowed_ip_cidrs = var.operator_cidrs
  }
}
