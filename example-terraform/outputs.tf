# Outputs for Azure Landing Zone

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Virtual Network
output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

# Subnets
output "subnets" {
  description = "Information about the subnets"
  value = {
    for name, subnet in azurerm_subnet.main : name => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
      service_endpoints = subnet.service_endpoints
    }
  }
}

# Network Security Group
output "network_security_group_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.main.name
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

# Key Vault
output "key_vault_name" {
  description = "Name of the key vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the key vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = azurerm_key_vault.main.vault_uri
}

# Storage Account
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

# Log Analytics Workspace
output "log_analytics_workspace_name" {
  description = "Name of the log analytics workspace"
  value       = local.monitoring_config.enable_monitoring ? azurerm_log_analytics_workspace.main[0].name : null
}

output "log_analytics_workspace_id" {
  description = "ID of the log analytics workspace"
  value       = local.monitoring_config.enable_monitoring ? azurerm_log_analytics_workspace.main[0].id : null
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID of the log analytics workspace"
  value       = local.monitoring_config.enable_monitoring ? azurerm_log_analytics_workspace.main[0].workspace_id : null
}

# Application Insights
output "application_insights_name" {
  description = "Name of the application insights"
  value       = local.monitoring_config.enable_monitoring ? azurerm_application_insights.main[0].name : null
}

output "application_insights_id" {
  description = "ID of the application insights"
  value       = local.monitoring_config.enable_monitoring ? azurerm_application_insights.main[0].id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the application insights"
  value       = local.monitoring_config.enable_monitoring ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of the application insights"
  value       = local.monitoring_config.enable_monitoring ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}

# Action Group
output "action_group_name" {
  description = "Name of the action group"
  value       = local.monitoring_config.enable_monitoring ? azurerm_monitor_action_group.main[0].name : null
}

output "action_group_id" {
  description = "ID of the action group"
  value       = local.monitoring_config.enable_monitoring ? azurerm_monitor_action_group.main[0].id : null
}

# Network Watcher
output "network_watcher_name" {
  description = "Name of the network watcher"
  value       = local.security_config.enable_network_watcher ? azurerm_network_watcher.main[0].name : null
}

output "network_watcher_id" {
  description = "ID of the network watcher"
  value       = local.security_config.enable_network_watcher ? azurerm_network_watcher.main[0].id : null
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "business_unit" {
  description = "Business unit"
  value       = var.business_unit
}

output "location" {
  description = "Azure region"
  value       = var.location
}

# Tags
output "common_tags" {
  description = "Common tags applied to resources"
  value       = local.common_tags
}

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the configuration"
  value = {
    environment           = var.environment
    business_unit         = var.business_unit
    location             = var.location
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    key_vault_name       = azurerm_key_vault.main.name
    storage_account_name = azurerm_storage_account.main.name
    monitoring_enabled   = local.monitoring_config.enable_monitoring
    security_enabled     = local.security_config.enable_network_watcher
    cost_management_enabled = local.cost_config.enable_cost_management
    compliance_enabled   = local.compliance_config.enable_policy_enforcement
  }
}

