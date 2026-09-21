# Inputs of the network module. Every name arrives built by the root
# (PC-IAC-025). Two CIDR blocks overlap exactly when their network addresses,
# truncated to the shorter prefix, are equal; the validations apply that test.

variable "client" {
  type        = string
  description = "Client code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.client))
    error_message = "The client code must be 2 to 10 lowercase letters or digits."
  }
}

variable "project" {
  type        = string
  description = "Project code, from MTS-IAC-101."

  validation {
    condition     = can(regex("^[a-z0-9]{2,15}$", var.project))
    error_message = "The project code must be 2 to 15 lowercase letters or digits."
  }
}

variable "environment" {
  type        = string
  description = "Environment code, from MTS-IAC-101."

  validation {
    condition     = contains(["shd", "eco", "fdev", "fstg", "fprd"], var.environment)
    error_message = "The environment must be one of shd, eco, fdev, fstg, or fprd."
  }
}

variable "reserved_cidrs" {
  type        = list(string)
  description = "Connected networks the VNet must not overlap, such as every AWS VPC of the estate."

  validation {
    condition     = alltrue([for cidr in var.reserved_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every reserved network must be an IPv4 CIDR block."
  }
}

variable "virtual_network" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    address_space       = string
  })
  description = "Standard name, resource group, programmatic region, and IPv4 address space of the VNet, such as lex-mts-fprd-vnet-dr in eastus2."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.virtual_network.name)) && length(var.virtual_network.name) <= 28 && length(var.virtual_network.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.virtual_network.location))
    error_message = "The VNet needs a standard name of at most 28 characters, a resource group, and a programmatic region name."
  }

  validation {
    condition     = can(cidrhost(var.virtual_network.address_space, 0)) && alltrue([for reserved in var.reserved_cidrs : !(cidrhost(format("%s/%d", split("/", var.virtual_network.address_space)[0], min(tonumber(split("/", var.virtual_network.address_space)[1]), tonumber(split("/", reserved)[1]))), 0) == cidrhost(format("%s/%d", split("/", reserved)[0], min(tonumber(split("/", var.virtual_network.address_space)[1]), tonumber(split("/", reserved)[1]))), 0))])
    error_message = "The VNet address space must be an IPv4 CIDR block that overlaps no reserved network."
  }
}

variable "subnets" {
  type = map(object({
    name              = string
    address_prefix    = string
    service_endpoints = optional(list(string), [])
  }))
  description = "Subnets keyed by a short key such as nodes. Every subnet is private: default outbound access is always off, so egress must be explicit."

  validation {
    condition     = length(var.subnets) > 0 && alltrue([for subnet in values(var.subnets) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", subnet.name)) && length(subnet.name) <= 28])
    error_message = "At least one subnet is required, each with a standard name of at most 28 characters."
  }

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : can(cidrhost(subnet.address_prefix, 0)) && tonumber(split("/", subnet.address_prefix)[1]) >= tonumber(split("/", var.virtual_network.address_space)[1]) && cidrhost(format("%s/%d", split("/", subnet.address_prefix)[0], min(tonumber(split("/", subnet.address_prefix)[1]), tonumber(split("/", var.virtual_network.address_space)[1]))), 0) == cidrhost(format("%s/%d", split("/", var.virtual_network.address_space)[0], min(tonumber(split("/", subnet.address_prefix)[1]), tonumber(split("/", var.virtual_network.address_space)[1]))), 0)])
    error_message = "Every subnet must be an IPv4 CIDR block inside the VNet address space."
  }

  validation {
    condition = alltrue(flatten([
      for first_key, first in var.subnets : [
        for second_key, second in var.subnets :
        first_key == second_key || !(cidrhost(format("%s/%d", split("/", first.address_prefix)[0], min(tonumber(split("/", first.address_prefix)[1]), tonumber(split("/", second.address_prefix)[1]))), 0) == cidrhost(format("%s/%d", split("/", second.address_prefix)[0], min(tonumber(split("/", first.address_prefix)[1]), tonumber(split("/", second.address_prefix)[1]))), 0))
      ]
    ]))
    error_message = "Subnets must not overlap each other."
  }

  validation {
    condition     = alltrue(flatten([for subnet in values(var.subnets) : [for endpoint in subnet.service_endpoints : contains(["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB", "Microsoft.CognitiveServices", "Microsoft.ContainerRegistry", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage", "Microsoft.Storage.Global", "Microsoft.Web"], endpoint)]]))
    error_message = "Service endpoints must be services azurerm_subnet supports, such as Microsoft.KeyVault or Microsoft.Storage."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the virtual network and its subnets besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
