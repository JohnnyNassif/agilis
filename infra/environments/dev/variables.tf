variable "subscription_id" {
  description = "Azure subscription ID for the dev environment."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID for the dev environment."
  type        = string
}

variable "environment" {
  description = "Environment name for tagging and resource naming."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for the dev resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Prefix used for dev resource names."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Optional extra tags for dev."
  type        = map(string)
  default     = {}
}

variable "log_analytics_retention_in_days" {
  description = "Log retention for dev telemetry."
  type        = number
  default     = 30
}

variable "archive_after_days" {
  description = "Days before dev blobs move to archive."
  type        = number
  default     = 30
}

variable "app_service_sku_name" {
  description = "App Service plan SKU for dev."
  type        = string
  default     = "F1"
}

variable "app_service_always_on" {
  description = "Enable Always On for dev App Service."
  type        = bool
  default     = false
}

variable "cosmos_mongo_database_max_throughput" {
  description = "Max RU/s for the dev Cosmos Mongo database."
  type        = number
  default     = 1000
}

variable "cosmos_free_tier_enabled" {
  description = "Enable Cosmos free tier in dev."
  type        = bool
  default     = true
}

variable "cosmos_enable_automatic_failover" {
  description = "Enable automatic failover for dev Cosmos (defaults to false)."
  type        = bool
  default     = false
}

variable "cosmos_account_name_suffix" {
  description = "Suffix for dev Cosmos account name."
  type        = string
  default     = "dev"
}

variable "app_service_name_suffix" {
  description = "Suffix for the dev App Service name."
  type        = string
  default     = "-dev1"
}

variable "storage_account_replication_type" {
  description = "Replication type for dev storage."
  type        = string
  default     = "ZRS"
}

variable "storage_account_tier" {
  description = "Tier for dev storage."
  type        = string
  default     = "Standard"
}

variable "storage_container_names" {
  description = "Blob containers for dev."
  type        = list(string)
  default     = ["phi-files"]
}

variable "key_vault_sku_name" {
  description = "SKU for dev Key Vault."
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention for dev Key Vault."
  type        = number
  default     = 90
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for dev Key Vault."
  type        = bool
  default     = false  # Disabled for dev to allow easier cleanup
}

variable "terraform_principal_id" {
  description = "Terraform service principal ID for Key Vault access (optional)."
  type        = string
  default     = null
}

variable "key_vault_additional_rbac_assignments" {
  description = "List of additional RBAC role assignments for dev Key Vault."
  type = list(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = []
}

variable "bastion_enabled" {
  description = "Enable Azure Bastion with Windows jump VM for dev."
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Bastion subnet in dev."
  type        = string
  default     = "10.10.3.0/27"
}

variable "bastion_vm_subnet_cidr" {
  description = "CIDR block for Windows VM subnet in dev."
  type        = string
  default     = "10.10.4.0/24"
}

variable "bastion_vm_size" {
  description = "Size of the Windows jump VM for dev."
  type        = string
  default     = "Standard_B1s"
}

variable "bastion_vm_admin_username" {
  description = "Administrator username for Windows jump VM in dev."
  type        = string
  default     = "azureadmin"
}

variable "bastion_vm_admin_password" {
  description = "Administrator password for Windows jump VM in dev (optional, will generate if not provided)."
  type        = string
  default     = null
  sensitive   = true
}

variable "bastion_auto_shutdown_enabled" {
  description = "Enable auto-shutdown schedule for dev jump VM."
  type        = bool
  default     = true
}

variable "bastion_auto_shutdown_time" {
  description = "Time for auto-shutdown in dev (24-hour format, e.g., '1800' for 6 PM)."
  type        = string
  default     = "1800"
}

variable "bastion_auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown schedule in dev."
  type        = string
  default     = "UTC"
}

