# Inputs of the key-vault module. The name arrives built by the root
# (PC-IAC-025).

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

variable "key_vault" {
  type = object({
    name                       = string
    resource_group_name        = string
    location                   = string
    soft_delete_retention_days = number
  })
  description = "Name of the vault (globally unique, built by the root), its resource group and programmatic region, and its soft-delete retention in days."

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{1,22}[A-Za-z0-9]$", var.key_vault.name)) && !strcontains(var.key_vault.name, "--")
    error_message = "The vault name must be 3-24 letters, digits, or single hyphens, starting with a letter and ending with a letter or digit."
  }

  validation {
    condition     = length(var.key_vault.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.key_vault.location))
    error_message = "The vault needs a resource group and a programmatic region name such as eastus2."
  }

  validation {
    condition     = var.key_vault.soft_delete_retention_days >= 7 && var.key_vault.soft_delete_retention_days <= 90
    error_message = "Soft-delete retention must be 7 to 90 days, the range Azure allows."
  }
}

variable "network_access" {
  type = object({
    allowed_ip_cidrs   = list(string)
    allowed_subnet_ids = list(string)
  })
  description = "What passes the vault firewall besides trusted Azure services: /32 addresses and subnet IDs (with the Microsoft.KeyVault service endpoint). Everything else is denied."

  validation {
    condition     = alltrue([for cidr in var.network_access.allowed_ip_cidrs : can(cidrhost(cidr, 0)) && endswith(cidr, "/32")])
    error_message = "Firewall addresses must be /32 blocks; 0.0.0.0/0 and ranges are refused."
  }

  validation {
    condition     = alltrue([for id in var.network_access.allowed_subnet_ids : can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", id))])
    error_message = "Allowed subnets must be subnet resource IDs."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the vault besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
