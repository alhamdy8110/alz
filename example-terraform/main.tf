# Main Terraform configuration for Azure Landing Zone

# Data sources
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_names.resource_group
  location = var.resource_group_location
  
  tags = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.resource_names.virtual_network
  address_space       = local.network_config.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}

# Subnets
resource "azurerm_subnet" "main" {
  for_each = local.network_config.subnets
  
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
  
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  dynamic "security_rule" {
    for_each = local.security_config.allowed_ip_ranges
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

# Associate NSG with subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = azurerm_subnet.main
  
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_config.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = local.key_vault_config.sku_name
  
  enabled_for_disk_encryption     = local.key_vault_config.enabled_for_disk_encryption
  enabled_for_deployment          = local.key_vault_config.enabled_for_deployment
  enabled_for_template_deployment = local.key_vault_config.enabled_for_template_deployment
  enable_rbac_authorization       = local.key_vault_config.enable_rbac_authorization
  purge_protection_enabled        = local.key_vault_config.purge_protection_enabled
  soft_delete_retention_days      = local.key_vault_config.soft_delete_retention_days
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  tags = local.common_tags
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
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

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = local.storage_config.name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = local.storage_config.account_tier
  account_replication_type = local.storage_config.account_replication_type
  
  enable_https_traffic_only       = local.storage_config.enable_https_traffic_only
  min_tls_version                 = local.storage_config.min_tls_version
  allow_nested_items_to_be_public = local.storage_config.allow_nested_items_to_be_public
  
  blob_properties {
    versioning_enabled = true
    change_feed_enabled = true
    change_feed_retention_in_days = 7
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
  
  tags = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  count = local.monitoring_config.enable_monitoring ? 1 : 0
  
  name                = local.log_analytics_config.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = local.log_analytics_config.sku
  retention_in_days   = local.log_analytics_config.retention_in_days
  
  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count = local.monitoring_config.enable_monitoring ? 1 : 0
  
  name                = local.application_insights_config.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main[0].id
  application_type    = local.application_insights_config.application_type
  retention_in_days   = local.application_insights_config.retention_in_days
  
  tags = local.common_tags
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  count = local.monitoring_config.enable_monitoring ? 1 : 0
  
  name                = local.resource_names.action_group
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alz-alerts"
  
  email_receiver {
    name          = "devops-team"
    email_address = "devops@company.com"
  }
  
  tags = local.common_tags
}

# Budget Alert
resource "azurerm_consumption_budget_resource_group" "main" {
  count = local.cost_config.enable_budget_alerts ? 1 : 0
  
  name              = "budget-${local.name_prefix}"
  resource_group_id = azurerm_resource_group.main.id
  
  amount     = local.cost_config.budget_amount
  time_grain = "Monthly"
  
  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }
  
  dynamic "notification" {
    for_each = local.cost_config.alert_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      
      contact_emails = ["devops@company.com"]
    }
  }
}

# Network Watcher
resource "azurerm_network_watcher" "main" {
  count = local.security_config.enable_network_watcher ? 1 : 0
  
  name                = "nw-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}

# Flow Logs
resource "azurerm_network_watcher_flow_log" "main" {
  count = local.security_config.enable_flow_logs ? 1 : 0
  
  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = azurerm_resource_group.main.name
  
  network_security_group_id = azurerm_network_security_group.main.id
  storage_account_id        = azurerm_storage_account.main.id
  enabled                   = true
  
  retention_policy {
    enabled = true
    days    = 7
  }
  
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main[0].workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main[0].location
    workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
    interval_in_minutes   = 10
  }
}

