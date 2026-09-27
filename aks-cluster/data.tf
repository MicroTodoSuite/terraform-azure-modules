# The authenticated client, whose tenant is the only tenant whose Entra groups
# may administer the cluster (a computational source PC-IAC-011 allows).
data "azurerm_client_config" "current" {
  provider = azurerm.project
}
