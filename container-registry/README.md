# container-registry

One Premium Azure container registry with no admin user and no anonymous pull,
so every pull and push authenticates with an Entra identity, a system-assigned
identity, and a firewall that denies by default and admits trusted Azure
services and the named `/32` addresses (for AKS, the cluster's static egress
address). Registry network rules exist only on the Premium SKU. Grant `AcrPull` or
`AcrPush` through `managed-identity` role assignments scoped to
`container_registry_id`.

## Network exposure

The registry keeps its public endpoint (`public_network_access_enabled = true`),
and SonarCloud reports `terraform:S6329` on it. The finding is accepted, not
fixed:

- Disabling public access overrides the firewall and leaves the registry
  reachable only through private endpoints and trusted Azure services. The AKS
  nodes would need a private endpoint and its private DNS zone, which no module
  of the disaster-recovery estate provides. The mirror jobs that copy signed
  images from ECR (`mirror-to-acr`, `mirror-platform-images`) run on
  GitHub-hosted runners, which cannot reach a private endpoint at all. GitHub
  Actions is not one of the registry's trusted services.
- Private endpoints and IP rules both need the Premium SKU. Basic and Standard
  cannot restrict network access at all, so the module refuses them.

The controls that apply with the endpoint on:

- The firewall denies by default and admits only the `/32` addresses the root
  names. The module refuses `0.0.0.0/0` and ranges.
- Only trusted Azure services, such as a registry import or Microsoft Defender,
  bypass the firewall. ACR Tasks do not.
- There is no admin user and no anonymous pull, so every request authenticates
  with an Entra identity that holds `AcrPull` or `AcrPush`.

Until the decision is recorded as a row in `docs/iac-exceptions.md` through its
own reviewed pull request, the registry carries no `NOSONAR`. Once the row
exists, a `NOSONAR` comment on the line SonarCloud reports cites it.

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
