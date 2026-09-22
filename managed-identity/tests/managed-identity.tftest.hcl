# Plan-time tests of the managed-identity module against a mocked Azure
# provider (PC-IAC-018). Like an IAM role, the module owns one identity, its
# trust (federated credentials), and its permissions (role assignments, with
# an optional custom role), so every grant an identity holds is reviewed in
# one place.
mock_provider "azurerm" {
  alias = "project"
}

# Mock computed values are unknown at plan unless an override supplies them.
override_resource {
  target          = azurerm_user_assigned_identity.this
  override_during = plan
  values = {
    id           = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security/providers/Microsoft.ManagedIdentity/userAssignedIdentities/lex-mts-fprd-id-drseed"
    principal_id = "dddddddd-0000-0000-0000-00000000000d"
    client_id    = "dddddddd-1111-1111-1111-11111111111d"
  }
}

override_resource {
  target          = azurerm_role_definition.custom
  override_during = plan
  values = {
    role_definition_resource_id = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/providers/Microsoft.Authorization/roleDefinitions/eeeeeeee-0000-0000-0000-00000000000e"
  }
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  identity = {
    name                = "lex-mts-fprd-id-drseed"
    resource_group_name = "lex-mts-fprd-rg-security"
    location            = "eastus2"
  }
  federated_credentials = {
    azuredr = {
      name    = "github-azure-dr"
      issuer  = "https://token.actions.githubusercontent.com"
      subject = "repo:MicroTodoSuite/.github:environment:azure-dr"
    }
  }
  custom_role = {
    name  = "lex-mts-fprd-role-drseed"
    scope = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security"
    data_actions = [
      "Microsoft.KeyVault/vaults/secrets/getSecret/action",
      "Microsoft.KeyVault/vaults/secrets/setSecret/action",
      "Microsoft.KeyVault/vaults/secrets/readMetadata/action",
    ]
  }
  role_assignments = {
    vault = {
      scope           = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security/providers/Microsoft.KeyVault/vaults/lex-mts-fprd-kv-dr"
      use_custom_role = true
    }
    registry = {
      scope                = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-registry/providers/Microsoft.ContainerRegistry/registries/lexmtsfprdacrdr"
      role_definition_name = "AcrPull"
    }
  }
}

run "creates_the_named_identity_with_governance_tags" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "lex-mts-fprd-id-drseed" && azurerm_user_assigned_identity.this.resource_group_name == "lex-mts-fprd-rg-security" && azurerm_user_assigned_identity.this.location == "eastus2"
    error_message = "The identity must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.tags["Name"] == "lex-mts-fprd-id-drseed" && azurerm_user_assigned_identity.this.tags["Environment"] == "fprd" && azurerm_user_assigned_identity.this.tags["ManagedBy"] == "terraform"
    error_message = "The identity must carry its Name and the governance tags."
  }

  assert {
    condition     = output.identity_name == "lex-mts-fprd-id-drseed" && output.identity_principal_id == "dddddddd-0000-0000-0000-00000000000d"
    error_message = "The module must output the identity name and principal."
  }
}

run "trusts_exactly_the_named_subjects" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = length(azurerm_federated_identity_credential.this) == 1
    error_message = "The identity must trust exactly one credential per entry, and no other."
  }

  assert {
    condition     = azurerm_federated_identity_credential.this["azuredr"].name == "github-azure-dr" && azurerm_federated_identity_credential.this["azuredr"].issuer == "https://token.actions.githubusercontent.com" && azurerm_federated_identity_credential.this["azuredr"].subject == "repo:MicroTodoSuite/.github:environment:azure-dr"
    error_message = "Each credential must trust one exact issuer and subject."
  }

  assert {
    condition     = tolist(azurerm_federated_identity_credential.this["azuredr"].audience) == tolist(["api://AzureADTokenExchange"]) && azurerm_federated_identity_credential.this["azuredr"].user_assigned_identity_id == azurerm_user_assigned_identity.this.id
    error_message = "Each credential must belong to this identity and accept only the Entra token-exchange audience."
  }
}

run "grants_exactly_the_named_permissions" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = toset(azurerm_role_definition.custom[0].permissions[0].data_actions) == toset(["Microsoft.KeyVault/vaults/secrets/getSecret/action", "Microsoft.KeyVault/vaults/secrets/setSecret/action", "Microsoft.KeyVault/vaults/secrets/readMetadata/action"]) && length(coalesce(azurerm_role_definition.custom[0].permissions[0].actions, [])) == 0
    error_message = "The custom role must carry exactly the requested data actions and no control-plane action."
  }

  assert {
    condition     = azurerm_role_definition.custom[0].name == "lex-mts-fprd-role-drseed" && azurerm_role_definition.custom[0].scope == var.custom_role.scope && toset(azurerm_role_definition.custom[0].assignable_scopes) == toset([var.custom_role.scope])
    error_message = "The custom role must be defined on, and assignable within, its one scope only."
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 2
    error_message = "The identity must hold exactly one assignment per entry."
  }

  assert {
    condition     = azurerm_role_assignment.this["vault"].scope == var.role_assignments.vault.scope && azurerm_role_assignment.this["vault"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-00000000d0d0/providers/Microsoft.Authorization/roleDefinitions/eeeeeeee-0000-0000-0000-00000000000e" && azurerm_role_assignment.this["vault"].principal_id == "dddddddd-0000-0000-0000-00000000000d"
    error_message = "A custom-role assignment must grant this identity the module's custom role on its exact scope."
  }

  assert {
    condition     = azurerm_role_assignment.this["registry"].scope == var.role_assignments.registry.scope && azurerm_role_assignment.this["registry"].role_definition_name == "AcrPull" && azurerm_role_assignment.this["registry"].principal_id == "dddddddd-0000-0000-0000-00000000000d" && azurerm_role_assignment.this["registry"].principal_type == "ServicePrincipal"
    error_message = "A built-in assignment must grant this identity the named role on its exact scope."
  }
}

run "creates_no_trust_or_permission_by_default" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    federated_credentials = {}
    custom_role           = null
    role_assignments      = {}
  }

  assert {
    condition     = length(azurerm_federated_identity_credential.this) == 0 && length(azurerm_role_definition.custom) == 0 && length(azurerm_role_assignment.this) == 0
    error_message = "Without entries, the identity must hold no trust and no permission."
  }
}

run "rejects_a_non_standard_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    identity = {
      name                = "Seed_Identity"
      resource_group_name = "lex-mts-fprd-rg-security"
      location            = "eastus2"
    }
  }

  expect_failures = [var.identity]
}

run "rejects_a_wildcard_subject" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    federated_credentials = {
      azuredr = {
        name    = "github-azure-dr"
        issuer  = "https://token.actions.githubusercontent.com"
        subject = "repo:MicroTodoSuite/*"
      }
    }
  }

  expect_failures = [var.federated_credentials]
}

run "rejects_a_non_https_issuer" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    federated_credentials = {
      azuredr = {
        name    = "github-azure-dr"
        issuer  = "http://token.actions.githubusercontent.com"
        subject = "repo:MicroTodoSuite/.github:environment:azure-dr"
      }
    }
  }

  expect_failures = [var.federated_credentials]
}

run "rejects_a_wildcard_permission" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    custom_role = {
      name         = "lex-mts-fprd-role-drseed"
      scope        = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security"
      data_actions = ["Microsoft.KeyVault/vaults/secrets/*"]
    }
  }

  expect_failures = [var.custom_role]
}

run "rejects_a_subscription_wide_assignment" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    role_assignments = {
      broad = {
        scope                = "/subscriptions/00000000-0000-0000-0000-00000000d0d0"
        role_definition_name = "Reader"
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_an_assignment_naming_two_roles" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    role_assignments = {
      vault = {
        scope                = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security/providers/Microsoft.KeyVault/vaults/lex-mts-fprd-kv-dr"
        role_definition_name = "Key Vault Secrets User"
        use_custom_role      = true
      }
    }
  }

  expect_failures = [var.role_assignments]
}

run "rejects_a_custom_assignment_without_a_custom_role" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    custom_role = null
  }

  expect_failures = [var.role_assignments]
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
