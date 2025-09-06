# Terraform version constraints for Azure Verified Modules

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Azure Verified Modules version constraints
locals {
  module_versions = {
    vnet           = "~> 4.0"
    key_vault      = "~> 2.0"
    storage        = "~> 1.0"
    monitoring     = "~> 3.0"
    security_center = "~> 2.0"
    policy         = "~> 2.0"
    vm             = "~> 1.0"
    aks            = "~> 1.0"
  }
}

