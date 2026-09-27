# Plan-time tests of the network module against a mocked Azure provider
# (PC-IAC-018): one VNet whose subnets are always private, inside the VNet,
# mutually disjoint, and clear of every reserved network.
mock_provider "azurerm" {
  alias = "project"
}

variables {
  client      = "lex"
  project     = "mts"
  environment = "fprd"
  virtual_network = {
    name                = "lex-mts-fprd-vnet-dr"
    resource_group_name = "lex-mts-fprd-rg-network"
    location            = "eastus2"
    address_space       = "10.70.0.0/16"
  }
  reserved_cidrs = ["10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16", "10.40.0.0/16", "10.50.0.0/16"]
  subnets = {
    nodes = {
      name              = "lex-mts-fprd-snet-nodes"
      address_prefix    = "10.70.0.0/22"
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
    }
  }
}

run "creates_a_vnet_with_private_subnets" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  assert {
    condition     = azurerm_virtual_network.this.name == "lex-mts-fprd-vnet-dr" && toset(azurerm_virtual_network.this.address_space) == toset(["10.70.0.0/16"]) && azurerm_virtual_network.this.location == "eastus2"
    error_message = "The VNet must carry the name, range, and region the root gave."
  }

  assert {
    condition     = azurerm_virtual_network.this.tags["Name"] == "lex-mts-fprd-vnet-dr" && azurerm_virtual_network.this.tags["ManagedBy"] == "terraform"
    error_message = "The VNet must carry its Name and the governance tags."
  }

  assert {
    condition     = azurerm_subnet.this["nodes"].name == "lex-mts-fprd-snet-nodes" && tolist(azurerm_subnet.this["nodes"].address_prefixes) == tolist(["10.70.0.0/22"]) && azurerm_subnet.this["nodes"].virtual_network_name == "lex-mts-fprd-vnet-dr"
    error_message = "Each subnet must carry its name and range inside this VNet."
  }

  assert {
    condition     = azurerm_subnet.this["nodes"].default_outbound_access_enabled == false
    error_message = "Every subnet must be private: no default outbound access."
  }

  assert {
    condition     = toset([for endpoint in azurerm_subnet.this["nodes"].service_endpoint : endpoint.service]) == toset(["Microsoft.KeyVault", "Microsoft.Storage"])
    error_message = "Each subnet must carry exactly its requested service endpoints."
  }

  assert {
    condition     = output.virtual_network_name == "lex-mts-fprd-vnet-dr" && keys(output.subnet_names) == ["nodes"]
    error_message = "The module must output the VNet name and the subnet names by key."
  }
}

run "rejects_a_vnet_overlapping_a_reserved_network" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  # 10.50.0.0/16 was the planned Azure range (spec 009 research decision 8);
  # the AWS shd hub VPC owns it now.
  variables {
    virtual_network = {
      name                = "lex-mts-fprd-vnet-dr"
      resource_group_name = "lex-mts-fprd-rg-network"
      location            = "eastus2"
      address_space       = "10.50.0.0/16"
    }
    subnets = {
      nodes = {
        name           = "lex-mts-fprd-snet-nodes"
        address_prefix = "10.50.0.0/22"
      }
    }
  }

  expect_failures = [var.virtual_network]
}

run "rejects_a_subnet_outside_the_vnet" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    subnets = {
      nodes = {
        name           = "lex-mts-fprd-snet-nodes"
        address_prefix = "10.71.0.0/22"
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_overlapping_subnets" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    subnets = {
      nodes = {
        name           = "lex-mts-fprd-snet-nodes"
        address_prefix = "10.70.0.0/22"
      }
      other = {
        name           = "lex-mts-fprd-snet-other"
        address_prefix = "10.70.2.0/24"
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_an_unknown_service_endpoint" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    subnets = {
      nodes = {
        name              = "lex-mts-fprd-snet-nodes"
        address_prefix    = "10.70.0.0/22"
        service_endpoints = ["Microsoft.Everything"]
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_a_network_without_subnets" {
  command = plan

  providers = {
    azurerm.project = azurerm.project
  }

  variables {
    subnets = {}
  }

  expect_failures = [var.subnets]
}
