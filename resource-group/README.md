# resource-group

One Azure resource group with the governance tags and its `Name`, guarded by
the approved subscription: the plan stops when the authenticated client is in
any other subscription. Every Azure disaster-recovery root creates its
resource group through this module, so each root carries the guard.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `expected_subscription_id` | Approved subscription GUID. |
| `resource_group` | `name` (built by the root, at most 28 characters) and `location` (programmatic region). |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`resource_group_id`, `resource_group_name`.

## Example

```hcl
module "resource_group" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//resource-group?ref=resource-group-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client                   = var.client
  project                  = var.project
  environment              = var.environment
  expected_subscription_id = var.subscription_id
  resource_group           = local.resource_group
  additional_tags          = local.additional_tags
}
```

See [`sample/`](sample/).
