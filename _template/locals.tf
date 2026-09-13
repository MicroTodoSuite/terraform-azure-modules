# Local values: the governance tags every resource carries, since azurerm has no default tags (PC-IAC-004, PC-IAC-012).
locals {
  governance_tags = {
    Client      = var.client
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.governance_tags, var.additional_tags)
}
