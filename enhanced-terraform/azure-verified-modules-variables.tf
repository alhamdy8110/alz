# Variables for Azure Verified Modules example

# Environment Configuration
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

# Business Configuration
variable "organization_name" {
  description = "Organization name for resource naming"
  type        = string
  default     = "company"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "alz"
}

variable "business_unit" {
  description = "Business unit (ITS, BS, DG)"
  type        = string
  validation {
    condition     = contains(["ITS", "BS", "DG"], var.business_unit)
    error_message = "Business unit must be one of: ITS, BS, DG."
  }
}

# Network Configuration
variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subnet_names" {
  description = "Names for subnets"
  type        = list(string)
  default     = ["subnet-1", "subnet-2"]
}

# Security Configuration
variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for network security groups"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

# Compute Configuration
variable "create_vm" {
  description = "Whether to create a virtual machine"
  type        = bool
  default     = false
}

variable "create_aks" {
  description = "Whether to create an AKS cluster"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

# Cost Management
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

# Compliance
variable "enable_compliance" {
  description = "Enable compliance monitoring"
  type        = bool
  default     = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

