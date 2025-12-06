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
