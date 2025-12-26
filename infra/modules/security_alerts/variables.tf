variable "name_prefix" {
  description = "Prefix for naming resources (e.g., 'agilis-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for query-based alerts."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# Alert Configuration
variable "alert_email_addresses" {
  description = "List of email addresses to receive security alerts."
  type        = list(string)
  default     = []
}

variable "alert_sms_numbers" {
  description = "List of SMS phone numbers to receive security alerts (digits only, no formatting)."
  type        = list(string)
  default     = []
}

variable "alert_sms_country_code" {
  description = "Country code for SMS alerts (e.g., '1' for US)."
  type        = string
  default     = "1"
}

variable "alert_webhook_urls" {
  description = "List of webhook URLs to receive security alerts (e.g., Slack, Teams, PagerDuty)."
  type        = list(string)
  default     = []
}

variable "alert_severity" {
  description = "Severity level for alerts (0-4, where 0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)."
  type        = number
  default     = 1
  validation {
    condition     = var.alert_severity >= 0 && var.alert_severity <= 4
    error_message = "Alert severity must be between 0 and 4."
  }
}

variable "alert_frequency_minutes" {
  description = "Frequency in minutes to evaluate alert queries."
  type        = number
  default     = 5
}

variable "alert_time_window_minutes" {
  description = "Time window in minutes to query logs for alerts."
  type        = number
  default     = 15
}

# Resource IDs for Alert Rules
variable "frontdoor_profile_id" {
  description = "ID of the Front Door profile (for WAF alerts)."
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "ID of the Storage Account (for access pattern alerts)."
  type        = string
  default     = null
}

variable "cosmos_account_id" {
  description = "ID of the Cosmos DB account (for access pattern alerts)."
  type        = string
  default     = null
}

variable "app_service_id" {
  description = "ID of the App Service (for failed request alerts)."
  type        = string
  default     = null
}

variable "nsg_ids" {
  description = "List of NSG IDs (for network traffic alerts)."
  type        = list(string)
  default     = []
}

# Alert Enable/Disable Flags
variable "enable_keyvault_auth_alerts" {
  description = "Enable alerts for Key Vault failed authentication attempts."
  type        = bool
  default     = true
}

variable "enable_policy_violation_alerts" {
  description = "Enable alerts for Azure Policy compliance violations."
  type        = bool
  default     = true
}

variable "enable_frontdoor_waf_alerts" {
  description = "Enable alerts for Front Door WAF blocked requests."
  type        = bool
  default     = true
}

variable "enable_storage_access_alerts" {
  description = "Enable alerts for unusual Storage Account access patterns."
  type        = bool
  default     = true
}

variable "enable_cosmos_access_alerts" {
  description = "Enable alerts for unusual Cosmos DB access patterns."
  type        = bool
  default     = true
}

variable "enable_nsg_alerts" {
  description = "Enable alerts for NSG denied traffic."
  type        = bool
  default     = true
}

variable "enable_app_service_alerts" {
  description = "Enable alerts for App Service failed requests."
  type        = bool
  default     = true
}

# Alert Thresholds
variable "keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed authentication attempts to trigger alert."
  type        = number
  default     = 5
}

variable "frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests to trigger alert."
  type        = number
  default     = 10
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

variable "nsg_denied_traffic_threshold" {
  description = "Threshold for NSG denied packets to trigger alert."
  type        = number
  default     = 100
}

variable "app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests (4xx/5xx) to trigger alert."
  type        = number
  default     = 50
}

