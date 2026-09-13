# Plan-time tests against a mocked Azure provider; cover every validation and the main behaviour (PC-IAC-018).
mock_provider "azurerm" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  identity = {
    name                = "lex-mts-fprd-id-workload"
    resource_group_name = "lex-mts-fprd-rg-workload"
    location            = "centralus"
  }
}

run "creates_the_named_identity_with_governance_tags" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "lex-mts-fprd-id-workload" && azurerm_user_assigned_identity.this.location == "centralus"
    error_message = "The identity must carry the name and region the root gave."
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.tags["Environment"] == "fprd" && azurerm_user_assigned_identity.this.tags["ManagedBy"] == "terraform"
    error_message = "The identity must carry the governance tags, which azurerm does not add by default."
  }
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
