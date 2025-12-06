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
  default     = "S2"
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

