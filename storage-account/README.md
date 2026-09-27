# storage-account

One Azure StorageV2 account and its private containers, for Terraform state
and recovery copies. Encryption is doubled (infrastructure encryption), traffic
is HTTPS with TLS 1.2 only, access is by Entra identity only (shared keys and
public blobs are refused, and the portal defaults to Entra), blobs are
versioned, deleted blobs and containers are kept for `retention_days`, and the
firewall denies by default, admitting trusted Azure services, the named public
addresses, and the named subnets. The account carries `prevent_destroy`
(`iac-contracts.json`, PC-IAC-010).

The consuming root sets `storage_use_azuread = true` on its provider, because
the account refuses shared keys. Grant data access through `managed-identity`
role assignments scoped to `storage_account_id`.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `storage_account` | `name` (separator-free, 3-24 characters), `resource_group_name`, `location`, `replication_type`, `retention_days` (1-365). |
| `network_access` | `allowed_ip_addresses` (plain public IPv4) and `allowed_subnet_ids`. |
| `containers` | Map of `{name}`; every container is private. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`storage_account_id`, `storage_account_name`, `container_names`.

## Example

```hcl
module "state_storage" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//storage-account?ref=storage-account-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  storage_account = local.state_storage
  network_access  = local.state_storage_network_access
  containers      = local.state_containers
  additional_tags = local.additional_tags
}
```

See [`sample/`](sample/).
