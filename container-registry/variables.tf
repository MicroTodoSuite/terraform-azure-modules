# Inputs of the container-registry module. The name arrives built by the root
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

variable "container_registry" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    sku                 = string
  })
  description = "Separator-free, globally unique name of the registry (built by the root), its resource group and programmatic region, and its SKU, which must be Premium: only Premium registries take network rules."

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.container_registry.name))
    error_message = "The registry name must be 5 to 50 lowercase letters or digits, without separators (MTS-IAC-101)."
  }

  validation {
    condition     = length(var.container_registry.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.container_registry.location))
    error_message = "The registry needs a resource group and a programmatic region name."
  }

  validation {
    condition     = var.container_registry.sku == "Premium"
    error_message = "The registry must be Premium: network rules, and so a registry closed by default, exist only on the Premium SKU."
  }
}

variable "network_access" {
  type = object({
    allowed_ip_cidrs = list(string)
  })
  description = "What passes the registry firewall besides trusted Azure services: /32 addresses, such as the operators' and the cluster's static egress address. Everything else is denied."

  validation {
    condition     = alltrue([for cidr in var.network_access.allowed_ip_cidrs : can(cidrhost(cidr, 0)) && endswith(cidr, "/32")])
    error_message = "Firewall addresses must be /32 blocks; 0.0.0.0/0 and ranges are refused."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the registry besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
