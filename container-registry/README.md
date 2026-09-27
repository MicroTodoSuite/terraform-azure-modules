# container-registry

One Standard Azure container registry reached only through Microsoft Entra: no
admin user, no anonymous pull, and no static credential, so every pull and push
authenticates with an Entra identity that holds `AcrPull` or `AcrPush`. The
registry carries a system-assigned identity. Grant `AcrPull` or `AcrPush`
through `managed-identity` role assignments scoped to `container_registry_id`.

## Why Standard

The SKU is Standard by the maintainer-delegated lead decision of 2026-09-21,
and the module refuses Basic and Premium:

- Premium costs about USD 50 per 30 days, against an Azure for Students credit
  of USD 100 for 12 months.
- Premium's public IP rules cannot admit the GitHub-hosted ECR-to-ACR mirror
  runners (`mirror-to-acr`, `mirror-platform-images`, gitops spec 009 T131),
  which have no fixed egress address, so a Premium firewall would refuse the
  mirror.
- Standard takes no network rules at all: IP rules, service endpoints, and
  private endpoints exist only on Premium. The protection is identity, not
  network.

## Network exposure

The registry keeps its public endpoint (`public_network_access_enabled = true`)
and accepts connections from any network. SonarCloud reports `terraform:S6329`
on that line. **The finding is accepted, not fixed**: the
`container-registry` / `azurerm_container_registry.this` row of
[`docs/iac-exceptions.md`](../docs/iac-exceptions.md) records the decision, its
reason, and its expiry, and the `NOSONAR` comment on the line in `main.tf` cites
that row.

**Access control is Entra-only.** With the endpoint open, what protects the
registry is authentication:

- `admin_enabled = false`: no admin user and no shared password.
- `anonymous_pull_enabled = false`: no unauthenticated pull.
- The module creates no token, scope map, or other static credential, and
  outputs none.
- Every request needs a Microsoft Entra identity (a workload or managed
  identity, or a user) with `AcrPull` or `AcrPush` on the registry.

The row expires when the mirror gains a fixed egress address and Premium fits
the disaster-recovery budget, or when Standard gains an applicable
network-isolation feature; the decision is revisited then.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `container_registry` | `name` (separator-free, 5-50 characters), `resource_group_name`, `location`, `sku` (`Standard`). |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`container_registry_id`, `container_registry_name`, `container_registry_endpoint`.
None of them is a credential.

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
