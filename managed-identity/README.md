# managed-identity

One user-assigned managed identity with its `Name` and the governance tags.
Its trust is granted by `federated-identity-credential` and its permissions by
`role-assignment`, so each is reviewed on its own.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `identity` | `name` (built by the root), `resource_group_name`, `location`. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`identity_id`, `identity_client_id`, `identity_principal_id`, `identity_name`.

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
