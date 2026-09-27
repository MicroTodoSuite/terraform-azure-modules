# key-vault

One Azure Key Vault that authorizes with Azure RBAC only (an explicit empty
`access_policy` removes any policy added by hand), keeps purge protection with
an explicit soft-delete retention, trusts the authenticated tenant, and denies
network access by default, admitting trusted Azure services, the named `/32`
addresses, and the named subnets. The vault carries `prevent_destroy`
(`iac-contracts.json`, PC-IAC-010).

The module creates no secret. Values are written by their owners' workflows,
so no secret passes through a Terraform plan or state. Grant access with
`managed-identity` role assignments scoped to `key_vault_id`.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `key_vault` | `name`, `resource_group_name`, `location`, `soft_delete_retention_days` (7-90). |
| `network_access` | `allowed_ip_cidrs` (`/32` only) and `allowed_subnet_ids`. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`key_vault_id`, `key_vault_name`, `key_vault_url`.

## Example

```hcl
module "key_vault" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//key-vault?ref=key-vault-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  key_vault       = local.key_vault
  network_access  = local.key_vault_network_access
  additional_tags = local.additional_tags
}
```

See [`sample/`](sample/).
