# container-registry

One Azure container registry with no admin user and no anonymous pull: every
pull and push authenticates with an Entra identity. Grant `AcrPull` or
`AcrPush` through `managed-identity` role assignments scoped to
`container_registry_id`.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `container_registry` | `name` (separator-free, 5-50 characters), `resource_group_name`, `location`, `sku`. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`container_registry_id`, `container_registry_name`, `container_registry_endpoint`.

## Example

```hcl
module "container_registry" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//container-registry?ref=container-registry-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client             = var.client
  project            = var.project
  environment        = var.environment
  container_registry = local.container_registry
  additional_tags    = local.additional_tags
}
```

See [`sample/`](sample/).
