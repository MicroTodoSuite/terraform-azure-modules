# aks-cluster

One AKS cluster:

- Kubernetes 1.35 with patch upgrades only inside that minor and node-image OS
  upgrades;
- Azure CNI Overlay with the Cilium data plane and Cilium network policy; pod,
  service, and DNS ranges validated clear of the VNet, of each other, and of
  every reserved network;
- the OIDC issuer and workload identity;
- Kubernetes RBAC through Entra ID, the named admin groups bound to
  cluster-admin, and local accounts disabled, so every API call carries an
  Entra identity;
- an API allowlist of `/32` addresses, never `0.0.0.0/0`;
- nodes in the given private subnet without public addresses, leaving through
  the Standard Load Balancer, optionally from Terraform-owned static outbound
  addresses that firewalls can admit;
- the given control-plane and kubelet identities — the cluster creates none;
- a cluster autoscaler bounded so `max_count * vcpus` fits the regional vCPU
  quota, with node auto-provisioning off.

The control-plane identity needs `Managed Identity Operator` on the kubelet
identity and `Network Contributor` on the node subnet before the cluster is
created, and `Network Contributor` on the resource group of any public IP a
LoadBalancer Service uses. Grant them with `managed-identity`.

## Inputs

| Name | Description |
| --- | --- |
| `client`, `project`, `environment` | Governance codes (MTS-IAC-101). |
| `cluster` | `name`, `resource_group_name`, `location`, `kubernetes_version`. |
| `identities` | `cluster_identity_id` and `kubelet = {id, client_id, object_id}`. |
| `network` | `subnet_id`, `vnet_cidr`, `pod_cidr`, `service_cidr`, `dns_service_ip`, `reserved_cidrs`, and optional `outbound_public_ip_ids`. |
| `api_server_authorized_ip_ranges` | `/32` operator addresses. |
| `system_node_pool` | `vm_size`, `vcpus`, `min_count`, `max_count`. |
| `regional_vcpu_quota` | The quota `max_count * vcpus` must fit. |
| `admin_group_object_ids` | Entra groups bound to cluster-admin. |
| `additional_tags` | Tags besides the governance tags. |

## Outputs

`cluster_id`, `cluster_name`, `oidc_issuer_url`, `kubernetes_version`,
`api_server_authorized_cidrs`, `node_resource_group_name`. No output carries a
kubeconfig.

## Example

```hcl
module "aks_cluster" {
  source = "git::https://github.com/MicroTodoSuite/terraform-azure-modules.git//aks-cluster?ref=aks-cluster-v1.0.0"

  providers = {
    azurerm.project = azurerm.principal
  }

  client                          = var.client
  project                         = var.project
  environment                     = var.environment
  cluster                         = local.cluster
  identities                      = local.cluster_identities
  network                         = local.cluster_network
  api_server_authorized_ip_ranges = var.api_server_authorized_cidrs
  system_node_pool                = var.system_node_pool
  regional_vcpu_quota             = var.regional_vcpu_quota
  admin_group_object_ids          = var.cluster_admin_group_object_ids
  additional_tags                 = local.additional_tags
}
```

See [`sample/`](sample/).
