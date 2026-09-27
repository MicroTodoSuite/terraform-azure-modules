# Inputs of the resource-group module. The name arrives built by the root
# (PC-IAC-025); the approved subscription is the value the DR preflight
# verifies.

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

variable "expected_subscription_id" {
  type        = string
  description = "Approved Azure subscription ID. The plan stops unless the authenticated client is in this subscription."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.expected_subscription_id))
    error_message = "The expected subscription must be a lowercase subscription GUID."
  }
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Standard name of the resource group, such as lex-mts-fprd-rg-network, and its Azure region by programmatic name, such as eastus2."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.resource_group.name)) && length(var.resource_group.name) <= 28
    error_message = "The resource group name must be lowercase letters and digits separated by hyphens, at most 28 characters (MTS-IAC-101)."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9]+$", var.resource_group.location))
    error_message = "The location must be a programmatic Azure region name, such as eastus2, never a display name."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the resource group besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
