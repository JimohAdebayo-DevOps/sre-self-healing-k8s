terraform {
  required_version = ">= 1.5.0"
  # This mathematically links local Terraform to remote Zero-Trust vault
  backend "azurerm" {
    resource_group_name  = "rg-gridops-tfstate-001"
    storage_account_name = "gridopstfstate24438"
    container_name       = "tfstate"
    key                  = "multicloud.terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "134ebc3a-530f-430d-ad74-d2eec91a6d90"
}
