variable "name_prefix" {
  description = "Prefix for naming monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where monitoring resources are created."
  type        = string
}

variable "retention_in_days" {
  description = "Retention period in days for Log Analytics workspace."
  type        = number
  default     = 30
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace (PerGB2018, Free, etc.)."
  type        = string
  default     = "PerGB2018"
}

variable "app_service_id" {
  description = "Resource ID of the App Service to enable diagnostics for."
  type        = string
  default     = null
}

variable "cosmos_account_id" {
  description = "Resource ID of the Cosmos DB account to enable diagnostics for."
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Resource ID of the Storage account to enable diagnostics for."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to enable diagnostics for."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to monitoring resources."
  type        = map(string)
}

