variable "name_prefix" {
  description = "Prefix for naming Sentinel resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where Sentinel resources will be created."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace where Sentinel will be onboarded."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "tags" {
  description = "Tags to apply to Sentinel resources."
  type        = map(string)
  default     = {}
}

# Resource IDs for Data Connectors and Analytics Rules
variable "key_vault_id" {
  description = "ID of the Key Vault (for Key Vault data connector)."
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "ID of the Storage Account (for Storage data connector and analytics rules)."
  type        = string
  default     = null
}

variable "cosmos_account_id" {
  description = "ID of the Cosmos DB account (for analytics rules)."
  type        = string
  default     = null
}

variable "app_service_id" {
  description = "ID of the App Service (for analytics rules)."
  type        = string
  default     = null
}

variable "frontdoor_profile_id" {
  description = "ID of the Front Door profile (for analytics rules)."
  type        = string
  default     = null
}

# Data Connector Enable/Disable Flags
variable "enable_azure_activity_connector" {
  description = "Enable Azure Activity Log data connector."
  type        = bool
  default     = true
}

variable "enable_security_center_connector" {
  description = "Enable Azure Security Center data connector."
  type        = bool
  default     = true
}

variable "enable_key_vault_connector" {
  description = "NOTE: Key Vault logs are collected via diagnostic settings, not a Sentinel data connector. This variable is kept for compatibility but has no effect."
  type        = bool
  default     = true
}

variable "enable_storage_connector" {
  description = "NOTE: Storage Account logs are collected via diagnostic settings, not a Sentinel data connector. This variable is kept for compatibility but has no effect."
  type        = bool
  default     = true
}

# Analytics Rule Enable/Disable Flags
variable "enable_keyvault_failed_auth_rule" {
  description = "Enable analytics rule for Key Vault failed authentication attempts."
  type        = bool
  default     = true
}

variable "enable_policy_violation_rule" {
  description = "Enable analytics rule for Azure Policy compliance violations."
  type        = bool
  default     = true
}

variable "enable_storage_unusual_access_rule" {
  description = "Enable analytics rule for unusual Storage Account access patterns."
  type        = bool
  default     = true
}

variable "enable_cosmos_unusual_access_rule" {
  description = "Enable analytics rule for unusual Cosmos DB access patterns."
  type        = bool
  default     = true
}

variable "enable_frontdoor_waf_rule" {
  description = "Enable analytics rule for Front Door WAF blocked requests."
  type        = bool
  default     = true
}

variable "enable_app_service_failed_requests_rule" {
  description = "Enable analytics rule for App Service failed requests."
  type        = bool
  default     = true
}

# Analytics Rule Configuration
variable "alert_frequency_minutes" {
  description = "Frequency in minutes to evaluate analytics rule queries."
  type        = number
  default     = 5
}

variable "alert_time_window_minutes" {
  description = "Time window in minutes to query logs for analytics rules."
  type        = number
  default     = 15
}

variable "enable_event_grouping" {
  description = "Enable event grouping for analytics rules (creates one alert per result)."
  type        = bool
  default     = true
}

# Analytics Rule Thresholds
variable "keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed authentication attempts to trigger alert."
  type        = number
  default     = 5
}

variable "storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for unusual Storage Account data transfer to trigger alert."
  type        = number
  default     = 1000 # 1 GB
}

variable "cosmos_unusual_access_threshold" {
  description = "Threshold for unusual Cosmos DB access requests to trigger alert."
  type        = number
  default     = 100
}

variable "cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB request units (RU) to consider unusual."
  type        = number
  default     = 1000
}

variable "frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests to trigger alert."
  type        = number
  default     = 10
}

variable "app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests (4xx/5xx) to trigger alert."
  type        = number
  default     = 50
}

# Customer Managed Key (Optional)
variable "enable_customer_managed_key" {
  description = "Enable customer-managed key encryption for Sentinel (requires Key Vault with key)."
  type        = bool
  default     = false
}

