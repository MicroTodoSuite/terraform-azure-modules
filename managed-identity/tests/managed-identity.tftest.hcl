# Plan-time tests of the managed-identity module against a mocked Azure
# provider (PC-IAC-018): one user-assigned identity with its Name and the
# governance tags. Federated credentials and role assignments are separate
# modules, so an identity's trust and permissions are each reviewed on their
# own.
mock_provider "azurerm" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  identity = {
    name                = "lex-mts-fprd-id-aks"
    resource_group_name = "lex-mts-fprd-rg-security"
    location            = "eastus2"
  }
}

run "creates_the_named_identity_with_governance_tags" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "lex-mts-fprd-id-aks" && azurerm_user_assigned_identity.this.resource_group_name == "lex-mts-fprd-rg-security" && azurerm_user_assigned_identity.this.location == "eastus2"
    error_message = "The identity must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.tags["Name"] == "lex-mts-fprd-id-aks" && azurerm_user_assigned_identity.this.tags["Environment"] == "fprd" && azurerm_user_assigned_identity.this.tags["ManagedBy"] == "terraform"
    error_message = "The identity must carry its Name and the governance tags."
  }

  assert {
    condition     = output.identity_name == "lex-mts-fprd-id-aks"
    error_message = "The module must output the identity name."
  }
}

run "rejects_a_non_standard_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    identity = {
      name                = "AKS_Identity"
      resource_group_name = "lex-mts-fprd-rg-security"
      location            = "eastus2"
    }
  }

  expect_failures = [var.identity]
}

run "rejects_a_display_name_location" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    identity = {
      name                = "lex-mts-fprd-id-aks"
      resource_group_name = "lex-mts-fprd-rg-security"
      location            = "East US 2"
    }
  }

  expect_failures = [var.identity]
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
