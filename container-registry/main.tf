# One Standard container registry reached only through Microsoft Entra: the
# admin user and anonymous pull stay disabled and the module issues no static
# credential, so every pull and push authenticates with an Entra identity that
# holds AcrPull or AcrPush. The protection is identity, not network: Standard
# takes no network rules, and Premium, whose IP rules could close the endpoint,
# was declined by the lead decision of 2026-09-21. Premium costs about USD 50
# per 30 days against an Azure for Students credit of USD 100 for 12 months,
# and its IP rules cannot admit the GitHub-hosted ECR-to-ACR mirror runners,
# which have no fixed egress address, so the firewall would refuse the mirror
# (gitops spec 009 T131).
resource "azurerm_container_registry" "this" {
  provider = azurerm.project

  name                   = var.container_registry.name
  resource_group_name    = var.container_registry.resource_group_name
  location               = var.container_registry.location
  sku                    = var.container_registry.sku
  admin_enabled          = false
  anonymous_pull_enabled = false

  # The public endpoint is accepted, not fixed: SonarCloud terraform:S6329 is
  # waived by the container-registry row of docs/iac-exceptions.md. Turning it
  # off leaves only private endpoints, which need Premium and which neither the
  # AKS nodes nor the GitHub-hosted mirror runners reach.
  public_network_access_enabled = true # NOSONAR terraform:S6329, accepted in docs/iac-exceptions.md (container-registry, azurerm_container_registry.this)

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.tags, { Name = var.container_registry.name })
}
