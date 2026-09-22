# Inputs of the public-ip module. The name and DNS label arrive built by the
# root (PC-IAC-025).

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

variable "public_ip" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
    domain_name_label   = optional(string)
  })
  description = "Standard name of the address, its resource group and programmatic region, and its optional DNS label; the provider FQDN is derived from the label, and an address without a label, such as an egress address, has no FQDN."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.public_ip.name)) && length(var.public_ip.name) <= 28 && length(var.public_ip.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.public_ip.location))
    error_message = "The address needs a standard name of at most 28 characters, a resource group, and a programmatic region name."
  }

  validation {
    condition     = var.public_ip.domain_name_label == null || can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.public_ip.domain_name_label))
    error_message = "The DNS label must be 3 to 63 lowercase letters, digits, or hyphens, starting with a letter."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the address besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
