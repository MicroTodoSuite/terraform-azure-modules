# The principal provider of the sample. The sample uses local state and no
# backend (PC-IAC-026).
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.0.1"
    }
  }
}

# azurerm 5.0 defaults resource_provider_registrations to "none"; it is stated
# here so the root's intent is explicit. The features block is required.
provider "azurerm" {
  alias                           = "principal"
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"

  features {}
}
