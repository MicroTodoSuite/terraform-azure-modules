# Plan-time tests of the storage-account module against a mocked Azure
# provider (PC-IAC-018): one StorageV2 account with double encryption,
# Entra-only access, versioned and soft-deleted blobs, a default-deny
# firewall, and private containers. It serves Terraform state and recovery
# copies alike.
mock_provider "azurerm" {
  alias = "project"
}

override_resource {
  target          = azurerm_storage_account.this
  override_during = plan
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-state/providers/Microsoft.Storage/storageAccounts/lexmtsfprdsttfstate"
  }
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  storage_account = {
    name                = "lexmtsfprdsttfstate"
    resource_group_name = "lex-mts-fprd-rg-state"
    location            = "eastus2"
    replication_type    = "ZRS"
    retention_days      = 30
  }
  network_access = {
    allowed_ip_addresses = ["181.50.102.191", "186.112.71.16"]
    allowed_subnet_ids   = []
  }
  containers = {
    tfstate = {
      name = "tfstate"
    }
  }
}

run "creates_an_encrypted_entra_only_account" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_storage_account.this.name == "lexmtsfprdsttfstate" && azurerm_storage_account.this.resource_group_name == "lex-mts-fprd-rg-state" && azurerm_storage_account.this.location == "eastus2" && azurerm_storage_account.this.account_replication_type == "ZRS"
    error_message = "The account must carry the name, resource group, region, and replication the root gave."
  }

  assert {
    condition     = azurerm_storage_account.this.account_kind == "StorageV2" && azurerm_storage_account.this.infrastructure_encryption_enabled == true && azurerm_storage_account.this.https_traffic_only_enabled == true && azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "The account must be StorageV2 with infrastructure (double) encryption, HTTPS only, and TLS 1.2."
  }

  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == false && azurerm_storage_account.this.allow_nested_items_to_be_public == false && azurerm_storage_account.this.default_to_oauth_authentication == true
    error_message = "The account must refuse shared keys and public blobs; access is by Entra identity only."
  }

  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].versioning_enabled == true && azurerm_storage_account.this.blob_properties[0].delete_retention_policy[0].days == 30 && azurerm_storage_account.this.blob_properties[0].container_delete_retention_policy[0].days == 30
    error_message = "The account must keep blob versions and soft-delete blobs and containers for the requested days."
  }

  assert {
    condition     = azurerm_storage_account.this.network_rules[0].default_action == "Deny" && toset(azurerm_storage_account.this.network_rules[0].bypass) == toset(["AzureServices"]) && toset(azurerm_storage_account.this.network_rules[0].ip_rules) == toset(["181.50.102.191", "186.112.71.16"]) && length(azurerm_storage_account.this.network_rules[0].virtual_network_subnet_ids) == 0
    error_message = "The account must deny network access by default and admit only the named addresses and subnets."
  }

  assert {
    condition     = azurerm_storage_container.this["tfstate"].name == "tfstate" && azurerm_storage_container.this["tfstate"].container_access_type == "private" && azurerm_storage_container.this["tfstate"].storage_account_id == azurerm_storage_account.this.id
    error_message = "Every container must be private and belong to this account."
  }

  assert {
    condition     = azurerm_storage_account.this.tags["Name"] == "lexmtsfprdsttfstate" && azurerm_storage_account.this.tags["ManagedBy"] == "terraform"
    error_message = "The account must carry its Name and the governance tags."
  }

  assert {
    condition     = output.storage_account_name == "lexmtsfprdsttfstate" && keys(output.container_names) == ["tfstate"]
    error_message = "The module must output the account name and the container names by key."
  }
}

run "rejects_a_cidr_in_the_address_rules" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  # Storage firewall rules take plain public IPv4 addresses; /31 and /32
  # blocks are not allowed.
  variables {
    network_access = {
      allowed_ip_addresses = ["181.50.102.191/32"]
      allowed_subnet_ids   = []
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_a_private_address_rule" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network_access = {
      allowed_ip_addresses = ["10.70.0.4"]
      allowed_subnet_ids   = []
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_an_invalid_account_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    storage_account = {
      name                = "lex-mts-fprd-st-tfstate"
      resource_group_name = "lex-mts-fprd-rg-state"
      location            = "eastus2"
      replication_type    = "ZRS"
      retention_days      = 30
    }
  }

  expect_failures = [var.storage_account]
}

run "rejects_a_retention_outside_azure_limits" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    storage_account = {
      name                = "lexmtsfprdsttfstate"
      resource_group_name = "lex-mts-fprd-rg-state"
      location            = "eastus2"
      replication_type    = "ZRS"
      retention_days      = 400
    }
  }

  expect_failures = [var.storage_account]
}

run "rejects_an_unknown_replication_type" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    storage_account = {
      name                = "lexmtsfprdsttfstate"
      resource_group_name = "lex-mts-fprd-rg-state"
      location            = "eastus2"
      replication_type    = "XRS"
      retention_days      = 30
    }
  }

  expect_failures = [var.storage_account]
}

run "rejects_an_unknown_environment" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    environment = "dev"
  }

  expect_failures = [var.environment]
}
