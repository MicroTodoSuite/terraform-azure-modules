# Inputs. Keep the governance variables; replace the example service input with the module's own (PC-IAC-002).
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

variable "identity" {
  type = object({
    name                = string
    resource_group_name = string
    location            = string
  })
  description = "The user-assigned managed identity: its name, built by the root, and the resource group and Azure region it lives in."

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.identity.name)) && length(var.identity.name) >= 3 && length(var.identity.name) <= 28
    error_message = "The identity name must be 3 to 28 lowercase letters and digits separated by hyphens (MTS-IAC-101, inside Azure's 3 to 128 characters)."
  }

  validation {
    condition     = length(var.identity.resource_group_name) > 0 && can(regex("^[a-z0-9]+$", var.identity.location))
    error_message = "The identity needs a resource group name and an Azure region name such as centralus."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the identity besides the governance tags."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0])
    error_message = "Tag keys must not be empty."
  }
}
