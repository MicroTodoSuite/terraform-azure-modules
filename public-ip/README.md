# public-ip

One Standard SKU static IPv4 address, with an optional DNS label scoped to the
tenant (`TenantReuse`), so no other tenant can claim the FQDN. An address
without a label, such as a cluster's egress address, has no FQDN. Terraform owns the
address; an AKS LoadBalancer Service selects it with the
`service.beta.kubernetes.io/azure-pip-name` and
`service.beta.kubernetes.io/azure-load-balancer-resource-group` annotations and
never creates or deletes it. The cluster identity needs `Network Contributor`
on the address's resource group.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `public_ip` | `name`, `resource_group_name`, `location`, `domain_name_label` (optional). |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`public_ip_id`, `public_ip_name`, `public_ip_resource_group_name`,
`public_ip_endpoint`, `public_ip_dns_name`.

## Example

```hcl
module "ingress_public_ip" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//public-ip?ref=public-ip-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client          = var.client
  project         = var.project
  environment     = var.environment
  public_ip       = local.ingress_public_ip
  additional_tags = local.additional_tags
}
```

See [`sample/`](sample/).
