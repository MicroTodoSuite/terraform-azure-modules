# The aks-cluster sample: one call of the module, fed from locals.
module "aks_cluster" {
  source = "../"

  providers = {
    azurerm.project = azurerm.principal
  }

  client                          = var.client
  project                         = var.project
  environment                     = var.environment
  cluster                         = local.cluster
  identities                      = local.identities
  network                         = var.network
  api_server_authorized_ip_ranges = var.operator_cidrs
  system_node_pool                = local.system_node_pool
  regional_vcpu_quota             = 2
  admin_group_object_ids          = var.admin_group_object_ids
}
