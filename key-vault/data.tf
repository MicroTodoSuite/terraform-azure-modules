# The authenticated client, whose tenant is the only tenant the vault trusts
# (a computational source PC-IAC-011 allows).
data "azurerm_client_config" "current" {
  provider = azurerm.project
}
