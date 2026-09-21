# One user-assigned managed identity, its trust, and its permissions. Like an
# IAM role, every grant the identity holds is declared here: the federated
# credentials it accepts, an optional custom role, and its role assignments.
resource "azurerm_user_assigned_identity" "this" {
  provider = azurerm.project

  name                = var.identity.name
  resource_group_name = var.identity.resource_group_name
  location            = var.identity.location
  tags                = merge(local.tags, { Name = var.identity.name })
}

resource "azurerm_federated_identity_credential" "this" {
  provider = azurerm.project
  for_each = var.federated_credentials

  name                      = each.value.name
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = each.value.issuer
  subject                   = each.value.subject
}

resource "azurerm_role_definition" "custom" {
  provider = azurerm.project
  count    = var.custom_role == null ? 0 : 1

  name        = var.custom_role.name
  scope       = var.custom_role.scope
  description = "Custom permissions of the ${var.identity.name} identity."

  permissions {
    actions      = var.custom_role.actions
    data_actions = var.custom_role.data_actions
  }

  assignable_scopes = [var.custom_role.scope]
}

resource "azurerm_role_assignment" "this" {
  provider = azurerm.project
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.use_custom_role ? null : each.value.role_definition_name
  role_definition_id   = each.value.use_custom_role ? azurerm_role_definition.custom[0].role_definition_resource_id : null
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
}
