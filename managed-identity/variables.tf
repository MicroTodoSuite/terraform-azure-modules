# Inputs of the managed-identity module: the identity, its trust, and its
# permissions. Names arrive built by the root (PC-IAC-025).

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
    condition     = length(var.identity.resource_group_name) > 0 && can(regex("^[a-z][a-z0-9]+$", var.identity.location))
    error_message = "The identity needs a resource group name and a programmatic Azure region name such as eastus2."
  }
}

variable "federated_credentials" {
  type = map(object({
    name    = string
    issuer  = string
    subject = string
  }))
  description = "Tokens the identity trusts, keyed by a stable label: each one exact https issuer and one exact subject, such as a GitHub environment or a Kubernetes service account. The audience is always api://AzureADTokenExchange."
  default     = {}

  validation {
    condition     = length(var.federated_credentials) <= 20
    error_message = "An identity holds at most 20 federated credentials (Microsoft Entra limit)."
  }

  validation {
    condition = alltrue([
      for credential in values(var.federated_credentials) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{2,119}$", credential.name)) && startswith(credential.issuer, "https://") && length(credential.subject) > 0 && !strcontains(credential.subject, "*")
    ])
    error_message = "Each credential needs a 3-120 character name, an https issuer, and one exact subject; wildcards are refused."
  }
}

variable "custom_role" {
  type = object({
    name         = string
    scope        = string
    actions      = optional(list(string), [])
    data_actions = optional(list(string), [])
  })
  description = "Optional custom role for this identity: its standard name, the one resource group it is defined on and assignable within, and its exact actions. A custom role cannot be defined on a single resource; assign it there through role_assignments. Pass null for none."

  validation {
    condition     = var.custom_role == null || try(can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.custom_role.name)) && length(var.custom_role.name) <= 28 && can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+$", var.custom_role.scope)), false)
    error_message = "The custom role needs a standard name of at most 28 characters and a resource-group scope."
  }

  validation {
    condition     = var.custom_role == null || try(length(concat(var.custom_role.actions, var.custom_role.data_actions)) > 0 && alltrue([for action in concat(var.custom_role.actions, var.custom_role.data_actions) : !strcontains(action, "*")]), false)
    error_message = "The custom role needs at least one action, and no action may contain a wildcard."
  }
}

variable "role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = optional(string)
    use_custom_role      = optional(bool, false)
  }))
  description = "Roles granted to this identity, keyed by a stable label: each on one resource group or resource, naming either a built-in role or the module's custom role."
  default     = {}

  validation {
    condition     = alltrue([for assignment in values(var.role_assignments) : can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/.+$", assignment.scope))])
    error_message = "Every assignment is scoped to a resource group or a resource; subscription-wide grants are refused."
  }

  validation {
    condition     = alltrue([for assignment in values(var.role_assignments) : (assignment.role_definition_name != null) != assignment.use_custom_role])
    error_message = "Every assignment names exactly one of role_definition_name or use_custom_role."
  }

  validation {
    condition     = alltrue([for assignment in values(var.role_assignments) : !assignment.use_custom_role || var.custom_role != null])
    error_message = "An assignment that uses the custom role needs custom_role."
  }
}

variable "additional_tags" {
  type        = map(string)
  description = "Tags added to the identity besides the governance tags, such as Owner, CostCenter, and Repository."
  default     = {}

  validation {
    condition     = alltrue([for key in keys(var.additional_tags) : length(key) > 0 && key != "Name"])
    error_message = "Tag keys must not be empty and must not override Name."
  }
}
