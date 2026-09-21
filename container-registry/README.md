# container-registry

One Premium Azure container registry with no admin user and no anonymous pull,
so every pull and push authenticates with an Entra identity, a system-assigned
identity, and a firewall that denies by default and admits trusted Azure
services and the named `/32` addresses (for AKS, the cluster's static egress
address). Registry network rules exist only on the Premium SKU. Grant `AcrPull` or
`AcrPush` through `managed-identity` role assignments scoped to
`container_registry_id`.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `container_registry` | `name` (separator-free, 5-50 characters), `resource_group_name`, `location`, `sku` (`Premium`). |
| `network_access` | `allowed_ip_cidrs`: `/32` addresses the firewall admits. |
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
  network_access     = local.container_registry_network_access
  additional_tags    = local.additional_tags
}
```

See [`sample/`](sample/).
