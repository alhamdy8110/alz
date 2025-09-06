# Global variables for Azure Landing Zone

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, prod, sandbox."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Azure client ID (service principal)"
  type        = string
  sensitive   = true
  default     = null
}

variable "client_secret" {
  description = "Azure client secret (service principal)"
  type        = string
  sensitive   = true
  default     = null
}

# Naming convention variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "alz"
}

variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "company"
}

variable "business_unit" {
  description = "Business unit (ITS, BS, DG)"
  type        = string
  validation {
    condition     = contains(["ITS", "BS", "DG"], var.business_unit)
    error_message = "Business unit must be one of: ITS, BS, DG."
  }
}

# Resource group variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
  default     = "East US"
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment   = ""
    Project       = "Azure Landing Zone"
    Owner         = "DevOps Team"
    CostCenter    = "IT"
    Compliance    = "Required"
    Backup        = "Required"
    Monitoring    = "Required"
  }
}

# Network variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_configs" {
  description = "Subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = list(string)
    delegation = optional(object({
      name    = string
      service = string
    }))
  }))
  default = {
    "subnet-1" = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "subnet-2" = {
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }
}

# Security variables
variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for network security groups"
  type        = list(string)
  default     = []
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection"
  type        = bool
  default     = true
}

# Monitoring variables
variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Cost management variables
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds (percentage)"
  type        = list(number)
  default     = [50, 75, 90, 100]
}

# Compliance variables
variable "enable_policy_enforcement" {
  description = "Enable Azure Policy enforcement"
  type        = bool
  default     = true
}

variable "compliance_standards" {
  description = "Compliance standards to enforce"
  type        = list(string)
  default     = ["CIS", "NIST", "SOC2"]
}

