# One Key Vault: Azure RBAC only, purge protection, and a firewall that denies
# by default. The module never creates a secret; values are written by their
# owners' workflows, so no secret passes through Terraform plan or state.
resource "azurerm_key_vault" "this" {
  provider = azurerm.project

  name                       = var.key_vault.name
  resource_group_name        = var.key_vault.resource_group_name
  location                   = var.key_vault.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = var.key_vault.soft_delete_retention_days

  # Access is granted by role assignments; an explicit empty list removes any
  # access policy added outside Terraform.
  access_policy = []

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.network_access.allowed_ip_cidrs
    virtual_network_subnet_ids = var.network_access.allowed_subnet_ids
  }

  tags = merge(local.tags, { Name = var.key_vault.name })

  lifecycle {
    prevent_destroy = true
  }
}
