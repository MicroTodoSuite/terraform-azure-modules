# network

One Azure VNet and its subnets. Every subnet is private — default outbound
access is always off — so egress is explicit (for AKS, its Standard Load
Balancer). Subnets must lie inside the VNet and not overlap each other, the
VNet must overlap none of `reserved_cidrs` (every AWS VPC of the estate), and
each subnet may carry service endpoints so Key Vault and Storage can deny
public access by default.

This module owns `azurerm_virtual_network` and `azurerm_subnet`
(`iac-contracts.json`, PC-IAC-023).

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `virtual_network` | `name`, `resource_group_name`, `location`, `address_space` (one IPv4 CIDR block). |
| `reserved_cidrs` | Networks the VNet must not overlap. |
| `subnets` | Map of `{name, address_prefix, service_endpoints}` keyed by a short key. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`virtual_network_id`, `virtual_network_name`, `subnet_ids`, `subnet_names`.

## Example

```hcl
module "network" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//network?ref=network-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  virtual_network = local.virtual_network
  reserved_cidrs  = var.reserved_cidrs
  subnets         = local.subnets
  additional_tags = local.additional_tags
}
```

See [`sample/`](sample/).
