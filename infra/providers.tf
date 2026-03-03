provider "azurerm" {
  features {}
}

provider "azuread" {
  use_oidc = true
  tenant_id = data.azurerm_client_config.current.tenant_id
}
data "azurerm_client_config" "current" {}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}
