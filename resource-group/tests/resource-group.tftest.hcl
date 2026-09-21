# Plan-time tests of the resource-group module against a mocked Azure provider
# (PC-IAC-018). The subscription guard compares the authenticated client with
# the approved subscription, so every root that creates a resource group stops
# before planning against another subscription.
mock_provider "azurerm" {
  alias = "project"

  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-00000000d0d0"
      tenant_id       = "33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  client                   = "lex"
  project                  = "mts"
  environment              = "fprd"
  expected_subscription_id = "00000000-0000-0000-0000-00000000d0d0"
  resource_group = {
    name     = "lex-mts-fprd-rg-network"
    location = "eastus2"
  }
  additional_tags = {
    Owner = "infrastructure"
  }
}

run "creates_the_named_resource_group_with_governance_tags" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_resource_group.this.name == "lex-mts-fprd-rg-network" && azurerm_resource_group.this.location == "eastus2"
    error_message = "The resource group must carry the name and region the root gave."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["Name"] == "lex-mts-fprd-rg-network" && azurerm_resource_group.this.tags["Environment"] == "fprd" && azurerm_resource_group.this.tags["ManagedBy"] == "terraform" && azurerm_resource_group.this.tags["Owner"] == "infrastructure"
    error_message = "The resource group must carry its Name, the governance tags, and the additional tags."
  }

  assert {
    condition     = output.resource_group_name == "lex-mts-fprd-rg-network"
    error_message = "The module must output the resource group name."
  }
}

run "rejects_another_subscription" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  override_data {
    target = data.azurerm_client_config.current
    values = {
      subscription_id = "99999999-9999-9999-9999-999999999999"
    }
  }

  expect_failures = [azurerm_resource_group.this]
}

run "rejects_a_malformed_subscription_id" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    expected_subscription_id = "not-a-subscription"
  }

  expect_failures = [var.expected_subscription_id]
}

run "rejects_a_display_name_location" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    resource_group = {
      name     = "lex-mts-fprd-rg-network"
      location = "East US 2"
    }
  }

  expect_failures = [var.resource_group]
}

run "rejects_a_non_standard_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    resource_group = {
      name     = "Network_RG"
      location = "eastus2"
    }
  }

  expect_failures = [var.resource_group]
}

run "rejects_an_unknown_environment" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    environment = "prod"
  }

  expect_failures = [var.environment]
}
