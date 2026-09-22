# Plan-time tests of the public-ip module against a mocked Azure provider
# (PC-IAC-018): one Standard static IPv4 address with a DNS label scoped to the
# tenant, so a Kubernetes Service can select it by name without owning it and
# no other tenant can claim its FQDN.
mock_provider "azurerm" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  public_ip = {
    name                = "lex-mts-fprd-pip-ingress"
    resource_group_name = "lex-mts-fprd-rg-ingress"
    location            = "eastus2"
    domain_name_label   = "lex-mts-fprd-dr"
  }
}

run "creates_a_standard_static_address_with_a_tenant_scoped_label" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_public_ip.this.name == "lex-mts-fprd-pip-ingress" && azurerm_public_ip.this.resource_group_name == "lex-mts-fprd-rg-ingress" && azurerm_public_ip.this.location == "eastus2"
    error_message = "The address must carry the name, resource group, and region the root gave."
  }

  assert {
    condition     = azurerm_public_ip.this.sku == "Standard" && azurerm_public_ip.this.allocation_method == "Static" && azurerm_public_ip.this.ip_version == "IPv4"
    error_message = "The address must be a Standard SKU static IPv4 address."
  }

  assert {
    condition     = azurerm_public_ip.this.domain_name_label == "lex-mts-fprd-dr" && azurerm_public_ip.this.domain_name_label_scope == "TenantReuse"
    error_message = "The address must carry the requested DNS label, scoped to the tenant so no other tenant can claim the FQDN."
  }

  assert {
    condition     = azurerm_public_ip.this.tags["Name"] == "lex-mts-fprd-pip-ingress" && azurerm_public_ip.this.tags["ManagedBy"] == "terraform"
    error_message = "The address must carry its Name and the governance tags."
  }

  assert {
    condition     = output.public_ip_name == "lex-mts-fprd-pip-ingress" && output.public_ip_resource_group_name == "lex-mts-fprd-rg-ingress"
    error_message = "The module must output the address name and resource group for the Service annotations."
  }
}

run "creates_an_address_without_a_label" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  # An egress address needs no DNS name; without a label there is no scope
  # either.
  variables {
    public_ip = {
      name                = "lex-mts-fprd-pip-egress"
      resource_group_name = "lex-mts-fprd-rg-ingress"
      location            = "eastus2"
      domain_name_label   = null
    }
  }

  assert {
    condition     = azurerm_public_ip.this.name == "lex-mts-fprd-pip-egress" && azurerm_public_ip.this.sku == "Standard" && azurerm_public_ip.this.allocation_method == "Static"
    error_message = "An address without a label must still be a Standard static address."
  }

  assert {
    condition     = azurerm_public_ip.this.domain_name_label == null && azurerm_public_ip.this.domain_name_label_scope == null
    error_message = "An address without a label must carry neither a label nor a label scope."
  }
}

run "rejects_an_invalid_dns_label" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    public_ip = {
      name                = "lex-mts-fprd-pip-ingress"
      resource_group_name = "lex-mts-fprd-rg-ingress"
      location            = "eastus2"
      domain_name_label   = "Lex_MTS"
    }
  }

  expect_failures = [var.public_ip]
}

run "rejects_a_non_standard_name" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    public_ip = {
      name                = "Ingress_IP"
      resource_group_name = "lex-mts-fprd-rg-ingress"
      location            = "eastus2"
      domain_name_label   = "lex-mts-fprd-dr"
    }
  }

  expect_failures = [var.public_ip]
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
