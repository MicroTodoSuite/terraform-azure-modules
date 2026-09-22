# The authenticated client, whose subscription the guard compares with the
# approved one (a computational source PC-IAC-011 allows).
data "azurerm_client_config" "current" {
  provider = azurerm.project
}
