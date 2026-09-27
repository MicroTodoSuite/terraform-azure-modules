# Plan-time tests of the container-registry module against a mocked Azure
# provider (PC-IAC-018): one Standard registry reachable only through Entra
# identities, with no admin user and no anonymous pull, a system-assigned
# identity, and the public endpoint accepted under the terraform:S6329 row of
# docs/iac-exceptions.md. Standard takes no network rules, so the protection is
# identity, not network.
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

run "creates_a_standard_registry_reached_only_through_entra" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_container_registry.this.name == "lexmtsfprdacrdr" && azurerm_container_registry.this.resource_group_name == "lex-mts-fprd-rg-registry" && azurerm_container_registry.this.location == "eastus2"
    error_message = "The registry must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_container_registry.this.sku == "Standard"
    error_message = "The registry must be Standard (lead decision of 2026-09-21)."
  }

  assert {
    condition     = azurerm_container_registry.this.admin_enabled == false
    error_message = "The registry must not enable the admin user; there is no static credential."
  }

  assert {
    condition     = azurerm_container_registry.this.anonymous_pull_enabled == false
    error_message = "The registry must not allow anonymous pulls; every pull authenticates with an Entra identity."
  }

  assert {
    condition     = azurerm_container_registry.this.public_network_access_enabled == true && azurerm_container_registry.this.admin_enabled == false && azurerm_container_registry.this.anonymous_pull_enabled == false
    error_message = "The public endpoint is the accepted exposure (terraform:S6329) only while access is by Entra identity alone."
  }

  assert {
    condition     = length(azurerm_container_registry.this.identity) == 1 && azurerm_container_registry.this.identity[0].type == "SystemAssigned"
    error_message = "The registry must carry exactly one system-assigned managed identity."
  }

  assert {
    condition     = azurerm_container_registry.this.tags["Name"] == "lexmtsfprdacrdr" && azurerm_container_registry.this.tags["ManagedBy"] == "terraform" && azurerm_container_registry.this.tags["Environment"] == "fprd"
    error_message = "The registry must carry its Name and the governance tags."
  }

  assert {
    condition     = output.container_registry_name == "lexmtsfprdacrdr"
    error_message = "The module must output the registry name."
  }
}

run "rejects_the_premium_sku" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    container_registry = {
      name                = "lexmtsfprdacrdr"
      resource_group_name = "lex-mts-fprd-rg-registry"
      location            = "eastus2"
      sku                 = "Premium"
    }
  }

  expect_failures = [var.container_registry]
}

run "rejects_the_basic_sku" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    container_registry = {
      name                = "lexmtsfprdacrdr"
      resource_group_name = "lex-mts-fprd-rg-registry"
      location            = "eastus2"
      sku                 = "Basic"
    }
  }

  expect_failures = [var.container_registry]
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

run "rejects_a_tag_overriding_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    additional_tags = {
      Name = "anotherregistry"
    }
  }

  expect_failures = [var.additional_tags]
}
