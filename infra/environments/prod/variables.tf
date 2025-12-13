variable "subscription_id" {
  description = "Azure subscription ID for the prod environment."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID for the prod environment."
  type        = string
}

variable "environment" {
  description = "Environment name for tagging and resource naming."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for prod resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Prefix used for prod resource names."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Optional extra tags for prod."
  type        = map(string)
  default     = {}
}

variable "log_analytics_retention_in_days" {
  description = "Log retention for prod telemetry."
  type        = number
  default     = 30
}

variable "archive_after_days" {
  description = "Days before prod blobs move to archive."
  type        = number
  default     = 30
}

variable "app_service_sku_name" {
  description = "App Service plan SKU for prod."
  type        = string
  default     = "P1v3"
}

variable "cosmos_mongo_database_max_throughput" {
  description = "Max RU/s for the prod Cosmos Mongo database."
  type        = number
  default     = 4000
}

variable "cosmos_free_tier_enabled" {
  description = "Enable Cosmos free tier in prod (defaults to false)."
  type        = bool
  default     = false
}

variable "cosmos_enable_automatic_failover" {
  description = "Enable automatic failover for prod Cosmos."
  type        = bool
  default     = true
}

variable "cosmos_account_name_suffix" {
  description = "Suffix for prod Cosmos account name."
  type        = string
  default     = "prod"
}

variable "app_service_always_on" {
  description = "Enable Always On for prod App Service."
  type        = bool
  default     = true
}

variable "app_service_name_suffix" {
  description = "Suffix for the prod App Service name."
  type        = string
  default     = ""
}

variable "storage_account_replication_type" {
  description = "Replication type for prod storage."
  type        = string
  default     = "GRS"  # Geo-redundant for production
}

variable "storage_account_tier" {
  description = "Tier for prod storage."
  type        = string
  default     = "Standard"
}

variable "storage_container_names" {
  description = "Blob containers for prod."
  type        = list(string)
  default     = ["phi-files"]
}

variable "key_vault_sku_name" {
  description = "SKU for prod Key Vault."
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention for prod Key Vault."
  type        = number
  default     = 90
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for prod Key Vault (required for HIPAA compliance)."
  type        = bool
  default     = true  # Enabled for production
}

variable "terraform_principal_id" {
  description = "Terraform service principal ID for Key Vault access (optional)."
  type        = string
  default     = null
}

variable "key_vault_additional_rbac_assignments" {
  description = "List of additional RBAC role assignments for prod Key Vault."
  type = list(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = []
}

variable "bastion_enabled" {
  description = "Enable Azure Bastion with Windows jump VM for prod."
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Bastion subnet in prod."
  type        = string
  default     = "10.10.3.0/27"
}

variable "bastion_vm_subnet_cidr" {
  description = "CIDR block for Windows VM subnet in prod."
  type        = string
  default     = "10.10.4.0/24"
}

variable "bastion_vm_size" {
  description = "Size of the Windows jump VM for prod."
  type        = string
  default     = "Standard_B1s"
}

variable "bastion_vm_admin_username" {
  description = "Administrator username for Windows jump VM in prod."
  type        = string
  default     = "azureadmin"
}

variable "bastion_vm_admin_password" {
  description = "Administrator password for Windows jump VM in prod (required for production)."
  type        = string
  default     = null
  sensitive   = true
}

variable "bastion_auto_shutdown_enabled" {
  description = "Enable auto-shutdown schedule for prod jump VM."
  type        = bool
  default     = true
}

variable "bastion_auto_shutdown_time" {
  description = "Time for auto-shutdown in prod (24-hour format, e.g., '1800' for 6 PM)."
  type        = string
  default     = "1800"
}

variable "bastion_auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown schedule in prod."
  type        = string
  default     = "UTC"
}
