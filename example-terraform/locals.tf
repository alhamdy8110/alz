# Local values for Azure Landing Zone

locals {
  # Naming convention
  name_prefix = "${var.organization_name}-${var.project_name}-${var.business_unit}-${var.environment}"
  
  # Common tags with environment-specific values
  common_tags = merge(var.common_tags, {
    Environment    = var.environment
    BusinessUnit   = var.business_unit
    Project        = var.project_name
    ManagedBy      = "Terraform"
    Repository     = "https://github.com/${var.organization_name}/alz-${var.business_unit}-${var.environment}"
    LastUpdated    = timestamp()
  })
  
  # Resource naming
  resource_names = {
    resource_group     = "rg-${local.name_prefix}"
    virtual_network    = "vnet-${local.name_prefix}"
    key_vault          = "kv-${local.name_prefix}"
    storage_account    = "st${replace(local.name_prefix, "-", "")}"
    log_analytics      = "law-${local.name_prefix}"
    application_insights = "appi-${local.name_prefix}"
    action_group       = "ag-${local.name_prefix}"
    policy_assignment  = "pa-${local.name_prefix}"
  }
  
  # Environment-specific configurations
  environment_config = {
    dev = {
      vm_size           = "Standard_B2s"
      disk_type         = "Standard_LRS"
      backup_retention  = 7
      monitoring_level  = "Basic"
      auto_shutdown     = true
    }
    prod = {
      vm_size           = "Standard_D4s_v3"
      disk_type         = "Premium_LRS"
      backup_retention  = 30
      monitoring_level  = "Full"
      auto_shutdown     = false
    }
    sandbox = {
      vm_size           = "Standard_B1s"
      disk_type         = "Standard_LRS"
      backup_retention  = 3
      monitoring_level  = "Basic"
      auto_shutdown     = true
    }
  }
  
  # Current environment configuration
  current_env_config = local.environment_config[var.environment]
  
  # Network configuration
  network_config = {
    vnet_address_space = var.vnet_address_space
    subnets = {
      for name, config in var.subnet_configs : name => {
        name             = name
        address_prefixes = config.address_prefixes
        service_endpoints = config.service_endpoints
        delegation       = config.delegation
      }
    }
  }
  
  # Security configuration
  security_config = {
    allowed_ip_ranges = var.allowed_ip_ranges
    enable_ddos_protection = var.enable_ddos_protection
    enable_network_watcher = true
    enable_flow_logs = true
  }
  
  # Monitoring configuration
  monitoring_config = {
    enable_monitoring = var.enable_monitoring
    log_retention_days = var.log_retention_days
    enable_application_insights = true
    enable_activity_log = true
    enable_metric_alerts = true
  }
  
  # Cost management configuration
  cost_config = {
    budget_amount = var.budget_amount
    alert_thresholds = var.budget_alert_thresholds
    enable_cost_management = true
    enable_budget_alerts = true
  }
  
  # Compliance configuration
  compliance_config = {
    enable_policy_enforcement = var.enable_policy_enforcement
    compliance_standards = var.compliance_standards
    enable_governance = true
    enable_blueprint = true
  }
  
  # Service principal configuration
  service_principal_config = {
    client_id     = var.client_id
    client_secret = var.client_secret
    tenant_id     = var.tenant_id
    subscription_id = var.subscription_id
  }
  
  # Key Vault configuration
  key_vault_config = {
    name = local.resource_names.key_vault
    sku_name = "standard"
    enabled_for_disk_encryption = true
    enabled_for_deployment = false
    enabled_for_template_deployment = true
    enable_rbac_authorization = true
    purge_protection_enabled = var.environment == "prod" ? true : false
    soft_delete_retention_days = var.environment == "prod" ? 90 : 7
  }
  
  # Storage account configuration
  storage_config = {
    name = local.resource_names.storage_account
    account_tier = "Standard"
    account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
    enable_https_traffic_only = true
    min_tls_version = "TLS1_2"
    allow_nested_items_to_be_public = false
  }
  
  # Log Analytics configuration
  log_analytics_config = {
    name = local.resource_names.log_analytics
    sku = "PerGB2018"
    retention_in_days = local.monitoring_config.log_retention_days
  }
  
  # Application Insights configuration
  application_insights_config = {
    name = local.resource_names.application_insights
    application_type = "web"
    retention_in_days = local.monitoring_config.log_retention_days
  }
}

