# Backend configuration for Terraform state management
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  
  backend "azurerm" {
    # Backend configuration will be provided via command line or environment variables
    # This allows for environment-specific state storage
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  
  # Use managed identity when running in Azure
  use_msi = true
  
  # Fallback to service principal when running locally
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Configure the Azure AD Provider
provider "azuread" {
  # Use managed identity when running in Azure
  use_msi = true
  
  # Fallback to service principal when running locally
  client_id     = var.client_id
  client_secret = var.client_secret
  tenant_id     = var.tenant_id
}

