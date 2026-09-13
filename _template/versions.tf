# Terraform and provider requirements. Keep the minimum provider version compatible with every consuming root.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 5.0.0"
      configuration_aliases = [azurerm.project]
    }
  }
}
