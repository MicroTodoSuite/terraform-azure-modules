# managed-identity

One user-assigned managed identity, its trust, and its permissions. Like an
IAM role, every grant the identity holds is declared in one place:

- `federated_credentials`: tokens it accepts, each one exact https issuer and
  one exact subject, audience `api://AzureADTokenExchange`, at most 20;
- `custom_role`: an optional custom role with exact actions (no wildcard),
  defined on and assignable within one resource group;
- `role_assignments`: roles granted to this identity only, each on a resource
  group or resource (never a subscription), naming exactly one of a built-in
  role or the custom role.

This module owns `azurerm_role_assignment` (`iac-contracts.json`, PC-IAC-023).

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `identity` | `name` (built by the root), `resource_group_name`, `location`. |
| `federated_credentials` | Map of `{name, issuer, subject}`; empty by default. |
| `custom_role` | `{name, scope, actions, data_actions}` or `null`. |
| `role_assignments` | Map of `{scope, role_definition_name}` or `{scope, use_custom_role = true}`. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`identity_id`, `identity_client_id`, `identity_principal_id`, `identity_name`,
`federated_credential_ids`, `role_assignment_ids`.

## Example

```hcl
module "cluster_identity" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//managed-identity?ref=managed-identity-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  identity        = local.identities.cluster
  additional_tags = local.additional_tags
}
```

See [`sample/`](sample/).
