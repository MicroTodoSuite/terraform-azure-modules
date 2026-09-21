# Plan-time tests of the key-vault module against a mocked Azure provider
# (PC-IAC-018): one vault that authorizes with Azure RBAC only, keeps purge
# protection, and denies network access by default. The module creates no
# secret: values are written by their owners' workflows, never by Terraform.
mock_provider "azurerm" {
  alias = "project"

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  key_vault = {
    name                       = "lex-mts-fprd-kv-dr"
    resource_group_name        = "lex-mts-fprd-rg-security"
    location                   = "eastus2"
    soft_delete_retention_days = 90
  }
  network_access = {
    allowed_ip_cidrs = ["181.50.102.191/32", "186.112.71.16/32"]
    allowed_subnet_ids = [
      "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes",
    ]
  }
}

run "creates_an_rbac_only_vault_closed_by_default" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_key_vault.this.name == "lex-mts-fprd-kv-dr" && azurerm_key_vault.this.resource_group_name == "lex-mts-fprd-rg-security" && azurerm_key_vault.this.location == "eastus2"
    error_message = "The vault must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled == true && length(azurerm_key_vault.this.access_policy) == 0
    error_message = "The vault must authorize with Azure RBAC only; no access policy may exist (MTS-IAC-104)."
  }

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled == true && azurerm_key_vault.this.soft_delete_retention_days == 90
    error_message = "The vault must keep purge protection and the requested soft-delete retention (MTS-IAC-104)."
  }

  assert {
    condition     = azurerm_key_vault.this.tenant_id == "33333333-3333-3333-3333-333333333333"
    error_message = "The vault must trust the authenticated tenant only."
  }

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny" && azurerm_key_vault.this.network_acls[0].bypass == "AzureServices" && toset(azurerm_key_vault.this.network_acls[0].ip_rules) == toset(var.network_access.allowed_ip_cidrs) && toset(azurerm_key_vault.this.network_acls[0].virtual_network_subnet_ids) == toset(var.network_access.allowed_subnet_ids)
    error_message = "The vault must deny network access by default and admit only the named addresses and subnets."
  }

  assert {
    condition     = azurerm_key_vault.this.tags["Name"] == "lex-mts-fprd-kv-dr" && azurerm_key_vault.this.tags["ManagedBy"] == "terraform"
    error_message = "The vault must carry its Name and the governance tags."
  }

  assert {
    condition     = output.key_vault_name == "lex-mts-fprd-kv-dr"
    error_message = "The module must output the vault name."
  }
}

run "rejects_an_open_network_rule" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network_access = {
      allowed_ip_cidrs   = ["0.0.0.0/0"]
      allowed_subnet_ids = []
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_a_range_instead_of_an_address" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network_access = {
      allowed_ip_cidrs   = ["181.50.102.0/24"]
      allowed_subnet_ids = []
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_a_malformed_subnet_id" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network_access = {
      allowed_ip_cidrs   = []
      allowed_subnet_ids = ["lex-mts-fprd-snet-nodes"]
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_an_invalid_vault_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    key_vault = {
      name                       = "lex--kv"
      resource_group_name        = "lex-mts-fprd-rg-security"
      location                   = "eastus2"
      soft_delete_retention_days = 90
    }
  }

  expect_failures = [var.key_vault]
}

run "rejects_a_retention_outside_azure_limits" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    key_vault = {
      name                       = "lex-mts-fprd-kv-dr"
      resource_group_name        = "lex-mts-fprd-rg-security"
      location                   = "eastus2"
      soft_delete_retention_days = 3
    }
  }

  expect_failures = [var.key_vault]
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
