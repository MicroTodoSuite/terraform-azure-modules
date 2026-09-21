# Plan-time tests of the aks-cluster module against a mocked Azure provider
# (PC-IAC-018): one AKS 1.35 cluster on Azure CNI Overlay with Cilium, the OIDC
# issuer and workload identity, Kubernetes RBAC through Entra ID with local
# accounts disabled, a /32 API allowlist, private nodes, and a cluster
# autoscaler bounded by the regional vCPU quota. The cluster receives its
# subnet and identities; it creates neither.
mock_provider "azurerm" {
  alias = "project"

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  cluster = {
    name                = "lex-mts-fprd-aks-dr"
    resource_group_name = "lex-mts-fprd-rg-workload"
    location            = "eastus2"
    kubernetes_version  = "1.35"
  }
  identities = {
    cluster_identity_id = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security/providers/Microsoft.ManagedIdentity/userAssignedIdentities/lex-mts-fprd-id-aks"
    kubelet = {
      id        = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-security/providers/Microsoft.ManagedIdentity/userAssignedIdentities/lex-mts-fprd-id-kubelet"
      client_id = "bbbbbbbb-1111-1111-1111-11111111111b"
      object_id = "bbbbbbbb-0000-0000-0000-00000000000b"
    }
  }
  network = {
    subnet_id      = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes"
    vnet_cidr      = "10.70.0.0/16"
    pod_cidr       = "192.168.0.0/16"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
    reserved_cidrs = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16", "10.40.0.0/16", "10.50.0.0/16"]
  }
  api_server_authorized_ip_ranges = [
    "181.50.102.191/32",
    "186.112.71.16/32",
    "190.108.77.190/32",
    "200.3.193.225/32",
  ]
  system_node_pool = {
    vm_size   = "Standard_D2s_v5"
    vcpus     = 2
    min_count = 1
    max_count = 3
  }
  regional_vcpu_quota    = 6
  admin_group_object_ids = ["66666666-6666-6666-6666-666666666666"]
}

run "creates_an_overlay_cilium_cluster" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.name == "lex-mts-fprd-aks-dr" && azurerm_kubernetes_cluster.this.resource_group_name == "lex-mts-fprd-rg-workload" && azurerm_kubernetes_cluster.this.location == "eastus2"
    error_message = "The cluster must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.kubernetes_version == "1.35" && azurerm_kubernetes_cluster.this.automatic_upgrade_channel == "patch"
    error_message = "The cluster must run Kubernetes 1.35 and take patch upgrades only inside that minor."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin == "azure" && azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode == "overlay" && azurerm_kubernetes_cluster.this.network_profile[0].network_data_plane == "cilium" && azurerm_kubernetes_cluster.this.network_profile[0].network_policy == "cilium"
    error_message = "The cluster must use Azure CNI Overlay with the Cilium data plane and Cilium network policy."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].pod_cidr == "192.168.0.0/16" && azurerm_kubernetes_cluster.this.network_profile[0].service_cidr == "172.16.0.0/16" && azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip == "172.16.0.10"
    error_message = "The cluster must use exactly the verified pod, service, and DNS ranges."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type == "loadBalancer" && azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku == "standard"
    error_message = "Nodes must leave through the cluster's Standard Load Balancer, the explicit path a private subnet needs."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.tags["Name"] == "lex-mts-fprd-aks-dr" && azurerm_kubernetes_cluster.this.tags["ManagedBy"] == "terraform"
    error_message = "The cluster must carry its Name and the governance tags."
  }
}

run "authenticates_every_call_with_entra" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.oidc_issuer_enabled == true && azurerm_kubernetes_cluster.this.workload_identity_enabled == true
    error_message = "The cluster must enable the OIDC issuer and workload identity."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.role_based_access_control_enabled == true && azurerm_kubernetes_cluster.this.local_account_disabled == true
    error_message = "The cluster must enforce Kubernetes RBAC and disable local accounts, so every API call carries an Entra identity."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].tenant_id == "33333333-3333-3333-3333-333333333333" && toset(azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].admin_group_object_ids) == toset(["66666666-6666-6666-6666-666666666666"])
    error_message = "Exactly the named Entra groups of the authenticated tenant must administer the cluster."
  }

  assert {
    condition     = toset(azurerm_kubernetes_cluster.this.api_server_access_profile[0].authorized_ip_ranges) == toset(var.api_server_authorized_ip_ranges) && !contains(tolist(azurerm_kubernetes_cluster.this.api_server_access_profile[0].authorized_ip_ranges), "0.0.0.0/0")
    error_message = "The API server must admit exactly the approved addresses and never 0.0.0.0/0."
  }

  assert {
    condition     = toset(output.api_server_authorized_cidrs) == toset(var.api_server_authorized_ip_ranges)
    error_message = "The module must output the allowlist the cluster carries."
  }
}

run "runs_as_the_given_identities_in_the_given_subnet" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.identity[0].type == "UserAssigned" && toset(azurerm_kubernetes_cluster.this.identity[0].identity_ids) == toset([var.identities.cluster_identity_id])
    error_message = "The cluster must run as exactly the given user-assigned identity, never a service principal."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.kubelet_identity[0].user_assigned_identity_id == var.identities.kubelet.id && azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id == var.identities.kubelet.client_id && azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id == var.identities.kubelet.object_id
    error_message = "Nodes must pull images as the given pre-created kubelet identity."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].vnet_subnet_id == var.network.subnet_id && azurerm_kubernetes_cluster.this.default_node_pool[0].node_public_ip_enabled == false
    error_message = "Nodes must run in the given private subnet without public addresses."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.node_provisioning_profile[0].mode == "Manual" && azurerm_kubernetes_cluster.this.default_node_pool[0].auto_scaling_enabled == true && azurerm_kubernetes_cluster.this.default_node_pool[0].min_count == 1 && azurerm_kubernetes_cluster.this.default_node_pool[0].max_count == 3 && azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size == "Standard_D2s_v5"
    error_message = "Capacity must be the bounded cluster autoscaler on the reviewed size, with node auto-provisioning off."
  }
}

run "rejects_another_kubernetes_minor" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    cluster = {
      name                = "lex-mts-fprd-aks-dr"
      resource_group_name = "lex-mts-fprd-rg-workload"
      location            = "eastus2"
      kubernetes_version  = "1.34"
    }
  }

  expect_failures = [var.cluster]
}

run "rejects_a_pod_range_overlapping_the_vnet" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network = {
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes"
      vnet_cidr      = "10.70.0.0/16"
      pod_cidr       = "10.70.128.0/17"
      service_cidr   = "172.16.0.0/16"
      dns_service_ip = "172.16.0.10"
      reserved_cidrs = ["10.10.0.0/16"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_a_pod_range_overlapping_a_reserved_network" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network = {
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes"
      vnet_cidr      = "10.70.0.0/16"
      pod_cidr       = "10.0.0.0/8"
      service_cidr   = "172.16.0.0/16"
      dns_service_ip = "172.16.0.10"
      reserved_cidrs = ["10.10.0.0/16"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_a_service_range_overlapping_the_pod_range" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network = {
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes"
      vnet_cidr      = "10.70.0.0/16"
      pod_cidr       = "192.168.0.0/16"
      service_cidr   = "192.168.0.0/20"
      dns_service_ip = "192.168.0.10"
      reserved_cidrs = ["10.10.0.0/16"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_a_dns_address_outside_the_service_range" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network = {
      subnet_id      = "/subscriptions/00000000-0000-0000-0000-00000000d0d0/resourceGroups/lex-mts-fprd-rg-network/providers/Microsoft.Network/virtualNetworks/lex-mts-fprd-vnet-dr/subnets/lex-mts-fprd-snet-nodes"
      vnet_cidr      = "10.70.0.0/16"
      pod_cidr       = "192.168.0.0/16"
      service_cidr   = "172.16.0.0/16"
      dns_service_ip = "172.17.0.10"
      reserved_cidrs = ["10.10.0.0/16"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_an_open_api_allowlist" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    api_server_authorized_ip_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.api_server_authorized_ip_ranges]
}

run "rejects_an_empty_api_allowlist" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    api_server_authorized_ip_ranges = []
  }

  expect_failures = [var.api_server_authorized_ip_ranges]
}

run "rejects_an_autoscaler_beyond_the_vcpu_quota" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    system_node_pool = {
      vm_size   = "Standard_D2s_v5"
      vcpus     = 2
      min_count = 1
      max_count = 4
    }
  }

  expect_failures = [var.system_node_pool]
}

run "rejects_an_autoscaler_minimum_above_its_maximum" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    system_node_pool = {
      vm_size   = "Standard_D2s_v5"
      vcpus     = 2
      min_count = 3
      max_count = 2
    }
  }

  expect_failures = [var.system_node_pool]
}

run "rejects_a_cluster_without_administrators" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    admin_group_object_ids = []
  }

  expect_failures = [var.admin_group_object_ids]
}

run "rejects_a_malformed_subnet_id" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    network = {
      subnet_id      = "lex-mts-fprd-snet-nodes"
      vnet_cidr      = "10.70.0.0/16"
      pod_cidr       = "192.168.0.0/16"
      service_cidr   = "172.16.0.0/16"
      dns_service_ip = "172.16.0.10"
      reserved_cidrs = ["10.10.0.0/16"]
    }
  }

  expect_failures = [var.network]
}

run "rejects_an_unknown_environment" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    environment = "dev"
  }

  expect_failures = [var.environment]
}
