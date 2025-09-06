# Outputs for Azure Verified Modules example

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
  value       = module.virtual_network.vnet_name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.virtual_network.vnet_id
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network"
  value       = module.virtual_network.vnet_address_space
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = module.virtual_network.vnet_subnets
}

# Key Vault
output "key_vault_name" {
  description = "Name of the key vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_id" {
  description = "ID of the key vault"
  value       = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the key vault"
  value       = module.key_vault.key_vault_uri
}

# Storage Account
output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.storage_account_name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage_account.storage_account_id
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.storage_account.storage_account_primary_endpoint
}

# Log Analytics
output "log_analytics_workspace_name" {
  description = "Name of the log analytics workspace"
  value       = module.log_analytics.log_analytics_workspace_name
}

output "log_analytics_workspace_id" {
  description = "ID of the log analytics workspace"
  value       = module.log_analytics.log_analytics_workspace_id
}

output "log_analytics_workspace_workspace_id" {
  description = "Workspace ID of the log analytics workspace"
  value       = module.log_analytics.log_analytics_workspace_workspace_id
}

# Application Insights
output "application_insights_name" {
  description = "Name of the application insights"
  value       = module.log_analytics.application_insights_name
}

output "application_insights_id" {
  description = "ID of the application insights"
  value       = module.log_analytics.application_insights_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key of the application insights"
  value       = module.log_analytics.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string of the application insights"
  value       = module.log_analytics.application_insights_connection_string
  sensitive   = true
}

# Security Center
output "security_center_name" {
  description = "Name of the security center"
  value       = module.security_center.security_center_name
}

output "security_center_id" {
  description = "ID of the security center"
  value       = module.security_center.security_center_id
}

# Policy Assignment
output "policy_assignment_name" {
  description = "Name of the policy assignment"
  value       = module.policy_assignment.policy_assignment_name
}

output "policy_assignment_id" {
  description = "ID of the policy assignment"
  value       = module.policy_assignment.policy_assignment_id
}

# Virtual Machine (if created)
output "virtual_machine_name" {
  description = "Name of the virtual machine"
  value       = var.create_vm ? module.virtual_machine[0].vm_name : null
}

output "virtual_machine_id" {
  description = "ID of the virtual machine"
  value       = var.create_vm ? module.virtual_machine[0].vm_id : null
}

output "virtual_machine_public_ip" {
  description = "Public IP of the virtual machine"
  value       = var.create_vm ? module.virtual_machine[0].vm_public_ip : null
}

# AKS Cluster (if created)
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.create_aks ? module.aks_cluster[0].cluster_name : null
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = var.create_aks ? module.aks_cluster[0].cluster_id : null
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = var.create_aks ? module.aks_cluster[0].cluster_fqdn : null
}

output "aks_cluster_kube_config" {
  description = "Kube config for the AKS cluster"
  value       = var.create_aks ? module.aks_cluster[0].cluster_kube_config : null
  sensitive   = true
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

# Configuration Summary
output "configuration_summary" {
  description = "Summary of the configuration"
  value = {
    environment           = var.environment
    business_unit         = var.business_unit
    location             = var.location
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = module.virtual_network.vnet_name
    key_vault_name       = module.key_vault.key_vault_name
    storage_account_name = module.storage_account.storage_account_name
    log_analytics_name   = module.log_analytics.log_analytics_workspace_name
    security_center_name = module.security_center.security_center_name
    policy_assignment_name = module.policy_assignment.policy_assignment_name
    vm_created           = var.create_vm
    aks_created          = var.create_aks
    compliance_enabled   = var.enable_compliance
  }
}

