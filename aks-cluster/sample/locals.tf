# Name construction and ID injection for the aks-cluster sample.
locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  cluster = {
    name                = "${local.governance_prefix}-aks-sample"
    resource_group_name = var.resource_group_name
    location            = var.location
    kubernetes_version  = "1.35"
  }

  identities = {
    cluster_identity_id = var.cluster_identity_id
    kubelet             = var.kubelet_identity
  }

  system_node_pool = {
    vm_size   = "Standard_D2s_v5"
    vcpus     = 2
    min_count = 1
    max_count = 1
  }
}
