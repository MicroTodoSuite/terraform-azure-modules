# Plan-time tests of the container-registry module against a mocked Azure
# provider (PC-IAC-018): one registry reachable only through Entra identities,
# with no admin user and no anonymous pull.
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
    sku                 = "Standard"
  }
}

run "creates_a_registry_without_shared_credentials" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_container_registry.this.name == "lexmtsfprdacrdr" && azurerm_container_registry.this.resource_group_name == "lex-mts-fprd-rg-registry" && azurerm_container_registry.this.location == "eastus2" && azurerm_container_registry.this.sku == "Standard"
    error_message = "The registry must carry the name, resource group, region, and SKU the root gave."
  }

  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false && azurerm_container_registry.this.anonymous_pull_enabled == false
    error_message = "The registry must allow neither the admin user nor anonymous pulls; access is by Entra identity only."
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
      sku                 = "Standard"
    }
  }

  expect_failures = [var.container_registry]
}

run "rejects_an_unknown_sku" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    container_registry = {
      name                = "lexmtsfprdacrdr"
      resource_group_name = "lex-mts-fprd-rg-registry"
      location            = "eastus2"
      sku                 = "Gold"
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
