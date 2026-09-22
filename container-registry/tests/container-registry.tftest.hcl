# Plan-time tests of the container-registry module against a mocked Azure
# provider (PC-IAC-018): one registry reachable only through Entra identities,
# with no admin user and no anonymous pull, a system-assigned identity, and a
# firewall that denies by default and admits named /32 addresses. Network rules
# need the Premium SKU.
mock_provider "azurerm" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  container_registry = {
    name                = "lexmtsfprdacrdr"
    resource_group_name = "lex-mts-fprd-rg-registry"
    location            = "eastus2"
    sku                 = "Premium"
  }
  network_access = {
    allowed_ip_cidrs = ["181.50.102.191/32", "203.0.113.20/32"]
  }
}

run "creates_a_registry_without_shared_credentials" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_container_registry.this.name == "lexmtsfprdacrdr" && azurerm_container_registry.this.resource_group_name == "lex-mts-fprd-rg-registry" && azurerm_container_registry.this.location == "eastus2" && azurerm_container_registry.this.sku == "Premium"
    error_message = "The registry must carry the name, resource group, region, and SKU the root gave."
  }

  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false && azurerm_container_registry.this.anonymous_pull_enabled == false
    error_message = "The registry must allow neither the admin user nor anonymous pulls; access is by Entra identity only."
  }

  assert {
    condition     = azurerm_container_registry.this.identity[0].type == "SystemAssigned"
    error_message = "The registry must carry a system-assigned managed identity."
  }

  assert {
    condition     = azurerm_container_registry.this.tags["Name"] == "lexmtsfprdacrdr" && azurerm_container_registry.this.tags["ManagedBy"] == "terraform"
    error_message = "The registry must carry its Name and the governance tags."
  }

  assert {
    condition     = output.container_registry_name == "lexmtsfprdacrdr"
    error_message = "The module must output the registry name."
  }
}

run "denies_network_access_by_default" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_container_registry.this.network_rule_set[0].default_action == "Deny"
    error_message = "The registry firewall must deny network access by default."
  }

  assert {
    condition     = toset([for rule in azurerm_container_registry.this.network_rule_set[0].ip_rule : rule.ip_range]) == toset(["181.50.102.191/32", "203.0.113.20/32"]) && alltrue([for rule in azurerm_container_registry.this.network_rule_set[0].ip_rule : rule.action == "Allow"])
    error_message = "The registry firewall must admit exactly the named addresses."
  }

  assert {
    condition     = azurerm_container_registry.this.network_rule_bypass_option == "AzureServices"
    error_message = "Trusted Azure services, such as a registry import, must still reach the registry."
  }

  assert {
    condition     = azurerm_container_registry.this.network_rule_bypass_for_tasks_enabled == false
    error_message = "ACR Tasks must not bypass the registry firewall."
  }

  assert {
    condition     = azurerm_container_registry.this.public_network_access_enabled == true && azurerm_container_registry.this.network_rule_set[0].default_action == "Deny"
    error_message = "The public endpoint is the accepted exposure only behind a firewall that denies by default."
  }
}

run "rejects_a_sku_without_network_rules" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    container_registry = {
      name                = "lexmtsfprdacrdr"
      resource_group_name = "lex-mts-fprd-rg-registry"
      location            = "eastus2"
      sku                 = "Standard"
    }
  }

  expect_failures = [var.container_registry]
}

run "rejects_an_open_network_rule" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network_access = {
      allowed_ip_cidrs = ["0.0.0.0/0"]
    }
  }

  expect_failures = [var.network_access]
}

run "rejects_a_name_with_separators" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    container_registry = {
      name                = "lex-mts-fprd-acr-dr"
      resource_group_name = "lex-mts-fprd-rg-registry"
      location            = "eastus2"
      sku                 = "Premium"
    }
  }

  expect_failures = [var.container_registry]
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
