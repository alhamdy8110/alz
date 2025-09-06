# Backend configuration for Azure Verified Modules example

terraform {
  backend "azurerm" {
    # Backend configuration will be provided via command line or environment variables
    # This allows for environment-specific state storage
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

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
    storage {
      purge_soft_delete_on_destroy = false
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

