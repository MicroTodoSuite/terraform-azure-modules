# One AKS cluster on Azure CNI Overlay with Cilium. Every API call carries an
# Entra identity (Kubernetes RBAC, named admin groups, no local accounts), the
# API server admits only /32 operator addresses, nodes run without public
# addresses in the given private subnet and leave through the Standard Load
# Balancer, and capacity is a cluster autoscaler bounded by the regional vCPU
# quota. The cluster runs as the given identities and creates none.
resource "azurerm_kubernetes_cluster" "this" {
  provider = azurerm.project

  name                = var.cluster.name
  resource_group_name = var.cluster.resource_group_name
  location            = var.cluster.location
  dns_prefix          = var.cluster.name
  kubernetes_version  = var.cluster.kubernetes_version

  # Patch upgrades stay inside the reviewed minor.
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true
  local_account_disabled            = true

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = false
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identities.cluster_identity_id]
  }

  kubelet_identity {
    client_id                 = var.identities.kubelet.client_id
    object_id                 = var.identities.kubelet.object_id
    user_assigned_identity_id = var.identities.kubelet.id
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  # Node auto-provisioning would add capacity outside the reviewed quota.
  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                        = "system"
    temporary_name_for_rotation = "systemtmp"
    vm_size                     = var.system_node_pool.vm_size
    vnet_subnet_id              = var.network.subnet_id
    node_public_ip_enabled      = false
    auto_scaling_enabled        = true
    min_count                   = var.system_node_pool.min_count
    max_count                   = var.system_node_pool.max_count
    tags                        = merge(local.tags, { Name = var.cluster.name })
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.network.pod_cidr
    service_cidr        = var.network.service_cidr
    dns_service_ip      = var.network.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"

    # With Terraform-owned outbound addresses, egress leaves from a known
    # address that registry and vault firewalls can admit.
    dynamic "load_balancer_profile" {
      for_each = length(var.network.outbound_public_ip_ids) > 0 ? [var.network.outbound_public_ip_ids] : []

      content {
        outbound_ip_address_ids = load_balancer_profile.value
      }
    }
  }

  tags = merge(local.tags, { Name = var.cluster.name })
}
