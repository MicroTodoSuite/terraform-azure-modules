# One StorageV2 account and its private containers. Encryption is doubled
# (infrastructure encryption), access is by Entra identity only (no shared key,
# no public blob), deleted data is kept, and the firewall denies by default.
# The account carries prevent_destroy: it holds Terraform state or recovery
# copies that must outlive any teardown.
resource "azurerm_storage_account" "this" {
  provider = azurerm.project

  name                              = var.storage_account.name
  resource_group_name               = var.storage_account.resource_group_name
  location                          = var.storage_account.location
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.storage_account.replication_type
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.network_access.allowed_ip_addresses
    virtual_network_subnet_ids = var.network_access.allowed_subnet_ids
  }

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.storage_account.retention_days
    }

    container_delete_retention_policy {
      days = var.storage_account.retention_days
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.tags, { Name = var.storage_account.name })

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "this" {
  provider = azurerm.project
  for_each = var.containers

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
