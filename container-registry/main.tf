# One Premium container registry. The admin user and anonymous pull stay
# disabled, so every pull and push authenticates with an Entra identity
# (AcrPull, AcrPush), and the firewall denies by default: only the named
# addresses and trusted Azure services reach it.
resource "azurerm_container_registry" "this" {
  provider = azurerm.project

  name                   = var.container_registry.name
  resource_group_name    = var.container_registry.resource_group_name
  location               = var.container_registry.location
  sku                    = var.container_registry.sku
  admin_enabled          = false
  anonymous_pull_enabled = false

  # The public endpoint stays on, and SonarCloud terraform:S6329 reports it: the
  # registry is accepted with it rather than fixed (README, "Network exposure").
  # Turning it off overrides the firewall and leaves only private endpoints,
  # which neither the AKS nodes nor the GitHub-hosted mirror runners reach
  # without a private link the disaster-recovery estate does not have. The rule
  # set below denies every other address; ACR Tasks get no bypass.
  public_network_access_enabled         = true
  network_rule_bypass_option            = "AzureServices"
  network_rule_bypass_for_tasks_enabled = false

  network_rule_set {
    default_action = "Deny"
    ip_rule        = [for cidr in var.network_access.allowed_ip_cidrs : { action = "Allow", ip_range = cidr }]
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.tags, { Name = var.container_registry.name })
}
