# Example Terraform configuration using Azure Verified Modules

# Data sources
data "azurerm_client_config" "current" {}

# Local values
locals {
  name_prefix = "${var.organization_name}-${var.project_name}-${var.business_unit}-${var.environment}"
  
  common_tags = {
    Environment    = var.environment
    BusinessUnit   = var.business_unit
    Project        = var.project_name
    ManagedBy      = "Terraform"
    Repository     = "https://github.com/${var.organization_name}/alz-${var.business_unit}-${var.environment}-tf"
    LastUpdated    = timestamp()
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  
  tags = local.common_tags
}

# Virtual Network using Azure Verified Module
module "virtual_network" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"
  
  vnet_name           = "vnet-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  
  # Enable service endpoints
  subnet_service_endpoints = {
    (var.subnet_names[0]) = ["Microsoft.Storage", "Microsoft.KeyVault"]
    (var.subnet_names[1]) = ["Microsoft.Storage"]
  }
  
  # Enable network security groups
  nsg_ids = {
    (var.subnet_names[0]) = azurerm_network_security_group.main.id
    (var.subnet_names[1]) = azurerm_network_security_group.main.id
  }
  
  tags = local.common_tags
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  dynamic "security_rule" {
    for_each = var.allowed_ip_ranges
    content {
      name                       = "Allow-${security_rule.key}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }
  
  tags = local.common_tags
}

# Key Vault using Azure Verified Module
module "key_vault" {
  source  = "Azure/keyvault/azurerm"
  version = "~> 2.0"
  
  key_vault_name = "kv-${local.name_prefix}"
  location       = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Security configuration
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.environment == "prod"
  
  # Network access
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [module.virtual_network.vnet_subnets[0]]
  }
  
  # Access policies
  access_policies = [
    {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id
      
      key_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
      ]
      
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
      ]
      
      certificate_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
      ]
    }
  ]
  
  tags = local.common_tags
}

# Storage Account using Azure Verified Module
module "storage_account" {
  source  = "Azure/storage/azurerm"
  version = "~> 1.0"
  
  storage_account_name = "st${replace(local.name_prefix, "-", "")}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Security configuration
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Blob properties
  blob_properties = {
    versioning_enabled = true
    change_feed_enabled = true
    change_feed_retention_in_days = 7
    
    delete_retention_policy = {
      days = 7
    }
    
    container_delete_retention_policy = {
      days = 7
    }
  }
  
  tags = local.common_tags
}

# Log Analytics Workspace using Azure Verified Module
module "log_analytics" {
  source  = "Azure/monitoring/azurerm"
  version = "~> 3.0"
  
  log_analytics_workspace_name = "law-${local.name_prefix}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main.name
  
  # Configuration
  sku               = "PerGB2018"
  retention_in_days = var.log_retention_days
  
  # Application Insights
  application_insights_name = "appi-${local.name_prefix}"
  application_type         = "web"
  
  tags = local.common_tags
}

# Security Center using Azure Verified Module
module "security_center" {
  source  = "Azure/security-center/azurerm"
  version = "~> 2.0"
  
  security_center_name = "asc-${local.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Configuration
  pricing_tier = var.environment == "prod" ? "Standard" : "Free"
  
  # Auto provisioning
  auto_provision = true
  
  tags = local.common_tags
}

# Policy Assignment using Azure Verified Module
module "policy_assignment" {
  source  = "Azure/policy/azurerm"
  version = "~> 2.0"
  
  policy_assignment_name = "pa-${local.name_prefix}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  
  # Policy definitions
  policy_definitions = [
    {
      name = "Require HTTPS"
      policy_rule = jsonencode({
        if = {
          allOf = [
            {
              field = "type"
              equals = "Microsoft.Storage/storageAccounts"
            },
            {
              field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
              equals = "false"
            }
          ]
        }
        then = {
          effect = "deny"
        }
      })
    }
  ]
  
  tags = local.common_tags
}

# Virtual Machine using Azure Verified Module (if needed)
module "virtual_machine" {
  count = var.create_vm ? 1 : 0
  
  source  = "Azure/vm/azurerm"
  version = "~> 1.0"
  
  vm_name            = "vm-${local.name_prefix}"
  location           = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # VM configuration
  vm_size = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B2s"
  
  # Network configuration
  subnet_id = module.virtual_network.vnet_subnets[0]
  
  # Storage configuration
  storage_account_type = var.environment == "prod" ? "Premium_LRS" : "Standard_LRS"
  
  # Security configuration
  enable_encryption = true
  key_vault_id     = module.key_vault.key_vault_id
  
  tags = local.common_tags
}

# AKS Cluster using Azure Verified Module (if needed)
module "aks_cluster" {
  count = var.create_aks ? 1 : 0
  
  source  = "Azure/aks/azurerm"
  version = "~> 1.0"
  
  cluster_name      = "aks-${local.name_prefix}"
  location          = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Cluster configuration
  kubernetes_version = var.kubernetes_version
  node_count        = var.environment == "prod" ? 3 : 1
  
  # Network configuration
  vnet_subnet_id = module.virtual_network.vnet_subnets[0]
  
  # Security configuration
  enable_rbac = true
  enable_azure_policy = true
  
  # Monitoring
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  
  tags = local.common_tags
}

