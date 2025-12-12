variable "subscription_id" {
  description = "Azure subscription ID where resources will be provisioned."
  type        = string
}

variable "tenant_id" {
  description = "Azure Active Directory tenant ID."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier (e.g., dev, prod)."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Primary Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Short prefix used for resource naming (e.g., agilis)."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Additional tags to merge with the default project tags."
  type        = map(string)
  default     = {}
}

variable "vnet_address_space" {
  description = "CIDR blocks for the core virtual network."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "app_subnet_cidr" {
  description = "CIDR block allocated for the App Service integration subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR block allocated for private endpoints and data-plane services."
  type        = string
  default     = "10.10.2.0/24"
}

variable "app_service_sku_name" {
  description = "SKU name for the App Service plan (e.g., P1v3, S2)."
  type        = string
  default     = "F1"
}

variable "app_service_plan_capacity" {
  description = "Number of workers (instances) for the App Service plan."
  type        = number
  default     = 1
}

variable "app_service_always_on" {
  description = "Whether to enable Always On for the App Service."
  type        = bool
  default     = true
}

variable "app_service_app_settings" {
  description = "Additional App Service application settings."
  type        = map(string)
  default = {
    COSMOS_CONNECTION_STRING = "__vault_reference__"
    STORAGE_ACCOUNT_URL      = "__vault_reference__"
  }
}

variable "app_service_name_suffix" {
  description = "Optional suffix appended to the App Service name."
  type        = string
  default     = ""
}

variable "app_service_connection_strings" {
  description = "Optional connection strings injected into the App Service."
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "app_service_node_version" {
  description = "Node.js runtime version for the App Service."
  type        = string
  default     = "18-lts"
}

variable "cosmos_mongo_database_name" {
  description = "Name of the Cosmos Mongo database."
  type        = string
  default     = "appdb"
}

variable "cosmos_mongo_collection_name" {
  description = "Name of the Cosmos Mongo collection storing tenant data."
  type        = string
  default     = "patients"
}

variable "cosmos_mongo_collection_shard_key" {
  description = "Shard key used for the Cosmos Mongo collection."
  type        = string
  default     = "_id"
}

variable "cosmos_mongo_database_max_throughput" {
  description = "Autoscale max throughput (RU/s) for the Mongo database."
  type        = number
  default     = 4000
}

variable "cosmos_consistency_level" {
  description = "Cosmos consistency level (Strong, BoundedStaleness, Session, Eventual, ConsistentPrefix)."
  type        = string
  default     = "Session"
}

variable "cosmos_enable_automatic_failover" {
  description = "Enable automatic failover for Cosmos DB."
  type        = bool
  default     = false
}

variable "cosmos_free_tier_enabled" {
  description = "Enable Cosmos free tier (dev/test only)."
  type        = bool
  default     = false
}

variable "cosmos_server_version" {
  description = "Mongo server version for Cosmos DB."
  type        = string
  default     = "4.2"
}

variable "cosmos_analytical_storage_enabled" {
  description = "Enable analytical storage for Cosmos DB."
  type        = bool
  default     = false
}

variable "cosmos_continuous_backup_enabled" {
  description = "Enable continuous backup for point-in-time restore."
  type        = bool
  default     = true
}

variable "cosmos_account_name_suffix" {
  description = "Optional suffix appended to the Cosmos account name for uniqueness."
  type        = string
  default     = ""
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account (LRS/ZRS/etc)."
  type        = string
  default     = "ZRS"
}

variable "storage_account_tier" {
  description = "Tier for the storage account (Standard or Premium)."
  type        = string
  default     = "Standard"
}

variable "storage_container_names" {
  description = "List of blob container names to create."
  type        = list(string)
  default     = ["phi-files"]
}

variable "log_analytics_retention_in_days" {
  description = "Retention period in days for Log Analytics workspace data."
  type        = number
  default     = 30
}

variable "archive_after_days" {
  description = "Number of days before moving PHI blobs to an archive tier."
  type        = number
  default     = 30
}

variable "key_vault_sku_name" {
  description = "SKU name for Key Vault (standard or premium)."
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault."
  type        = number
  default     = 90
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault."
  type        = bool
  default     = true
}

variable "key_vault_cosmos_secret_name" {
  description = "Name of the secret in Key Vault for Cosmos connection string."
  type        = string
  default     = "cosmos-connection-string"
}

variable "key_vault_storage_key_secret_name" {
  description = "Name of the secret in Key Vault for Storage account key."
  type        = string
  default     = "storage-account-key"
}

variable "key_vault_storage_name_secret_name" {
  description = "Name of the secret in Key Vault for Storage account name."
  type        = string
  default     = "storage-account-name"
}

variable "terraform_principal_id" {
  description = "Principal ID of the Terraform service principal for Key Vault secret management (optional)."
  type        = string
  default     = null
}
