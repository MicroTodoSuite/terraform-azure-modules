# The principal provider of the sample. The sample uses local state.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0"
    }
  }
}

# azurerm 5.0 defaults resource_provider_registrations to "none"; it is stated here so the
# root's intent is explicit. The features block is required, even when empty.
provider "azurerm" {
  alias                           = "principal"
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"

  features {}
}
