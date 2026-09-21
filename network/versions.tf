# Terraform and provider requirements. A module declares only the minimum
# provider version; the consuming root pins the exact release (PC-IAC-006).
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 5.0.1"
      configuration_aliases = [azurerm.project]
    }
  }
}
