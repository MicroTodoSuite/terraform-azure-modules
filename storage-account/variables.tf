# Inputs of the storage-account module. The name arrives built by the root
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

variable "storage_account" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    replication_type    = string
    retention_days      = number
  })
  description = "Separator-free, globally unique name of the account (built by the root), its resource group and programmatic region, its replication, and how many days deleted blobs and containers are kept."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account.name))
    error_message = "The account name must be 3 to 24 lowercase letters or digits, without separators (MTS-IAC-101)."
  }

  validation {
    condition     = length(var.storage_account.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.storage_account.location)) && contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_account.replication_type)
    error_message = "The account needs a resource group, a programmatic region name, and a replication of LRS, ZRS, GRS, RAGRS, GZRS, or RAGZRS."
  }

  validation {
    condition     = var.storage_account.retention_days >= 1 && var.storage_account.retention_days <= 365
    error_message = "Blob and container retention must be 1 to 365 days, the range Azure allows."
  }
}

variable "network_access" {
  type = object({
    allowed_ip_addresses = list(string)
    allowed_subnet_ids   = list(string)
  })
  description = "What passes the account firewall besides trusted Azure services: public IPv4 addresses (the storage firewall takes plain addresses, not /32 blocks) and subnet IDs with the Microsoft.Storage service endpoint. Everything else is denied."

  validation {
    condition     = alltrue([for address in var.network_access.allowed_ip_addresses : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", address)) && can(cidrhost("${address}/32", 0))])
    error_message = "Firewall addresses must be plain IPv4 addresses; the storage firewall refuses /31 and /32 blocks."
  }

  validation {
    condition     = alltrue([for address in var.network_access.allowed_ip_addresses : !try(cidrhost(format("%s/%d", split("/", "${address}/32")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "10.0.0.0/8")[1]))), 0) == cidrhost(format("%s/%d", split("/", "10.0.0.0/8")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "10.0.0.0/8")[1]))), 0) || cidrhost(format("%s/%d", split("/", "${address}/32")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "172.16.0.0/12")[1]))), 0) == cidrhost(format("%s/%d", split("/", "172.16.0.0/12")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "172.16.0.0/12")[1]))), 0) || cidrhost(format("%s/%d", split("/", "${address}/32")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "192.168.0.0/16")[1]))), 0) == cidrhost(format("%s/%d", split("/", "192.168.0.0/16")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "192.168.0.0/16")[1]))), 0) || cidrhost(format("%s/%d", split("/", "${address}/32")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "127.0.0.0/8")[1]))), 0) == cidrhost(format("%s/%d", split("/", "127.0.0.0/8")[0], min(tonumber(split("/", "${address}/32")[1]), tonumber(split("/", "127.0.0.0/8")[1]))), 0), true)])
    error_message = "Firewall addresses must be public; private ranges reach the account through a subnet instead."
  }

  validation {
    condition     = alltrue([for id in var.network_access.allowed_subnet_ids : can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", id))])
    error_message = "Allowed subnets must be subnet resource IDs."
  }
}

variable "containers" {
  type = map(object({
    name = string
  }))
  description = "Private blob containers keyed by a stable label, such as tfstate."
  default     = {}

  validation {
    condition     = alltrue([for container in values(var.containers) : can(regex("^[a-z0-9](-?[a-z0-9])+$", container.name)) && length(container.name) >= 3 && length(container.name) <= 63])
    error_message = "Container names must be 3 to 63 lowercase letters, digits, or single hyphens."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the storage account besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
