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

variable "app_service_node_version" {
  description = "Node.js runtime version for App Service in dev."
  type        = string
  default     = "18-lts"
}

variable "app_service_enable_ip_restrictions" {
  description = "Enable IP restrictions on App Service in dev to only allow Front Door access (blocks direct Internet access). Set to true for production."
  type        = bool
  default     = false
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

variable "storage_enable_infrastructure_encryption" {
  description = "Enable infrastructure encryption (double encryption) for Storage Account in dev. Required for HIPAA compliance."
  type        = bool
  default     = true
}

variable "disable_public_access_automatically" {
  description = "Automatically disable public network access for Storage Account, Key Vault, and Cosmos DB after all resources are created. Set to false for dev/testing (allows manual testing), true for production/HIPAA compliance."
  type        = bool
  default     = false
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
  default     = false # Disabled for dev to allow easier cleanup
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

# Azure Front Door with WAF Configuration (MANDATORY for HIPAA compliance)
variable "frontdoor_enabled" {
  description = "Azure Front Door with WAF is MANDATORY for HIPAA compliance. This variable is kept for compatibility but Front Door is always enabled."
  type        = bool
  default     = true
}

variable "frontdoor_sku_name" {
  description = "SKU name for Front Door in dev (Standard_AzureFrontDoor or Premium_AzureFrontDoor)."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "frontdoor_waf_mode" {
  description = "WAF mode in dev: Detection (log only) or Prevention (block requests)."
  type        = string
  default     = "Prevention"
}

variable "frontdoor_waf_default_rule_set_action" {
  description = "Action for Microsoft Default Rule Set in dev (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
}

variable "frontdoor_waf_bot_rule_set_action" {
  description = "Action for Bot Manager Rule Set in dev (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
}

variable "frontdoor_custom_domain_name" {
  description = "Custom domain name for Front Door in dev (optional, e.g., api-dev.example.com)."
  type        = string
  default     = null
}

variable "frontdoor_health_probe_path" {
  description = "Path for Front Door health probe requests in dev."
  type        = string
  default     = "/"
}

variable "frontdoor_route_patterns" {
  description = "URL patterns to match for Front Door routing in dev."
  type        = list(string)
  default     = ["/*"]
}

# Azure Policy Variables
variable "policy_enable_hipaa_initiative" {
  description = "Enable Azure HIPAA/HITRUST compliance policy initiative assignment in dev."
  type        = bool
  default     = true
}

variable "policy_enable_custom_policies" {
  description = "Enable custom HIPAA-specific policy assignments in dev."
  type        = bool
  default     = true
}

variable "policy_management_group_id" {
  description = "Optional management group ID for policy assignment in dev. If not provided, policies are assigned at subscription level."
  type        = string
  default     = null
}

# Security Monitoring Alerts Configuration
variable "security_alerts_email_addresses" {
  description = "List of email addresses to receive security alerts in dev."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_numbers" {
  description = "List of SMS phone numbers to receive security alerts in dev."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_country_code" {
  description = "Country code for SMS alerts in dev."
  type        = string
  default     = "1"
}

variable "security_alerts_webhook_urls" {
  description = "List of webhook URLs to receive security alerts in dev."
  type        = list(string)
  default     = []
}

variable "security_alerts_severity" {
  description = "Severity level for security alerts in dev (0-4)."
  type        = number
  default     = 1
}

variable "security_alerts_frequency_minutes" {
  description = "Frequency in minutes to evaluate security alert queries in dev."
  type        = number
  default     = 5
}

variable "security_alerts_time_window_minutes" {
  description = "Time window in minutes to query logs for security alerts in dev."
  type        = number
  default     = 15
}

variable "security_alerts_enable_keyvault_auth" {
  description = "Enable Key Vault authentication alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_policy_violations" {
  description = "Enable policy violation alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_frontdoor_waf" {
  description = "Enable Front Door WAF alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_storage_access" {
  description = "Enable Storage access alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_cosmos_access" {
  description = "Enable Cosmos DB access alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_nsg" {
  description = "Enable NSG alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_enable_app_service" {
  description = "Enable App Service alerts in dev."
  type        = bool
  default     = true
}

variable "security_alerts_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed auth alerts in dev."
  type        = number
  default     = 5
}

variable "security_alerts_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests in dev."
  type        = number
  default     = 10
}

variable "security_alerts_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for Storage unusual access alerts in dev."
  type        = number
  default     = 1000
}

variable "security_alerts_cosmos_unusual_access_threshold" {
  description = "Threshold for Cosmos DB unusual access alerts in dev."
  type        = number
  default     = 100
}

variable "security_alerts_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB RU alerts in dev."
  type        = number
  default     = 1000
}

variable "security_alerts_nsg_denied_traffic_threshold" {
  description = "Threshold for NSG denied traffic alerts in dev."
  type        = number
  default     = 100
}

variable "security_alerts_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests alerts in dev."
  type        = number
  default     = 50
}

# ============================================================================
# Azure Sentinel Variables (Dev Environment)
# ============================================================================

variable "sentinel_enable_azure_activity_connector" {
  description = "Enable Azure Activity Log data connector for Sentinel in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_security_center_connector" {
  description = "Enable Azure Security Center data connector for Sentinel in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_key_vault_connector" {
  description = "Enable Azure Key Vault data connector for Sentinel in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_storage_connector" {
  description = "Enable Azure Storage Account data connector for Sentinel in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_keyvault_failed_auth_rule" {
  description = "Enable Sentinel analytics rule for Key Vault failed authentication attempts in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_policy_violation_rule" {
  description = "Enable Sentinel analytics rule for Azure Policy compliance violations in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_storage_unusual_access_rule" {
  description = "Enable Sentinel analytics rule for unusual Storage Account access patterns in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_cosmos_unusual_access_rule" {
  description = "Enable Sentinel analytics rule for unusual Cosmos DB access patterns in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_frontdoor_waf_rule" {
  description = "Enable Sentinel analytics rule for Front Door WAF blocked requests in dev."
  type        = bool
  default     = true
}

variable "sentinel_enable_app_service_failed_requests_rule" {
  description = "Enable Sentinel analytics rule for App Service failed requests in dev."
  type        = bool
  default     = true
}

variable "sentinel_alert_frequency_minutes" {
  description = "Frequency in minutes to evaluate Sentinel analytics rule queries in dev."
  type        = number
  default     = 5
}

variable "sentinel_alert_time_window_minutes" {
  description = "Time window in minutes to query logs for Sentinel analytics rules in dev."
  type        = number
  default     = 15
}

variable "sentinel_enable_event_grouping" {
  description = "Enable event grouping for Sentinel analytics rules in dev (creates one alert per result)."
  type        = bool
  default     = true
}

variable "sentinel_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed authentication attempts to trigger Sentinel alert in dev."
  type        = number
  default     = 5
}

variable "sentinel_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for unusual Storage Account data transfer to trigger Sentinel alert in dev."
  type        = number
  default     = 1000 # 1 GB
}

variable "sentinel_cosmos_unusual_access_threshold" {
  description = "Threshold for unusual Cosmos DB access requests to trigger Sentinel alert in dev."
  type        = number
  default     = 100
}

variable "sentinel_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB request units (RU) to consider unusual for Sentinel alerts in dev."
  type        = number
  default     = 1000
}

variable "sentinel_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests to trigger Sentinel alert in dev."
  type        = number
  default     = 10
}

variable "sentinel_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests (4xx/5xx) to trigger Sentinel alert in dev."
  type        = number
  default     = 50
}

variable "sentinel_enable_customer_managed_key" {
  description = "Enable customer-managed key encryption for Sentinel in dev (requires Key Vault with key)."
  type        = bool
  default     = false
}

# ============================================================================
# RBAC Module Variables
# ============================================================================

variable "rbac_admin_user_principal_ids" {
  description = "List of admin user principal IDs (Object IDs) for client admin access in dev. Supports up to 3 admin users. Set this for production (client account), leave empty for development (personal account)."
  type        = list(string)
  default     = []
}

variable "rbac_enable_admin_users" {
  description = "Enable RBAC assignments for admin users (client admins) in dev. Set to true for production (client account), false for development (personal account)."
  type        = bool
  default     = false
}

variable "rbac_enable_current_user_access" {
  description = "Enable RBAC assignment for current user in dev (useful for development/testing in personal Azure accounts). Set to false for production (client account)."
  type        = bool
  default     = true
}

# ============================================================================
# Static Web App Variables
# ============================================================================

variable "static_web_app_sku_tier" {
  description = "SKU tier for Static Web App in dev (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_sku_size" {
  description = "SKU size for Static Web App in dev (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_app_settings" {
  description = "App settings (environment variables) for Static Web App in dev (e.g., API endpoint URLs)."
  type        = map(string)
  default     = {}
}

variable "static_web_app_custom_domain_name" {
  description = "Custom domain name for Static Web App in dev (optional, e.g., app-dev.example.com)."
  type        = string
  default     = null
}

# ============================================================================
# Whiteboard Static Web App Variables
# ============================================================================

variable "static_web_app_whiteboard_sku_tier" {
  description = "SKU tier for Whiteboard Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_whiteboard_sku_size" {
  description = "SKU size for Whiteboard Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_whiteboard_app_settings" {
  description = "App settings for Whiteboard Static Web App."
  type        = map(string)
  default     = {}
}

# ============================================================================
# Telehealth Static Web App Variables
# ============================================================================

variable "static_web_app_telehealth_sku_tier" {
  description = "SKU tier for Telehealth Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_telehealth_sku_size" {
  description = "SKU size for Telehealth Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "static_web_app_telehealth_app_settings" {
  description = "App settings for Telehealth Static Web App."
  type        = map(string)
  default     = {}
}

# ============================================================================
# Whiteboard App Service Variables
# ============================================================================

variable "app_service_whiteboard_sku_name" {
  description = "SKU name for Whiteboard App Service plan (e.g., B1 for minimal load)."
  type        = string
  default     = "B1"
}

variable "app_service_whiteboard_plan_capacity" {
  description = "Number of workers for Whiteboard App Service plan."
  type        = number
  default     = 1
}

variable "app_service_whiteboard_always_on" {
  description = "Whether to enable Always On for Whiteboard App Service."
  type        = bool
  default     = false
}

# ============================================================================
# Telehealth App Service Variables
# ============================================================================

variable "app_service_telehealth_sku_name" {
  description = "SKU name for Telehealth App Service plan (e.g., B1 for minimal load)."
  type        = string
  default     = "B1"
}

variable "app_service_telehealth_plan_capacity" {
  description = "Number of workers for Telehealth App Service plan."
  type        = number
  default     = 1
}

variable "app_service_telehealth_always_on" {
  description = "Whether to enable Always On for Telehealth App Service."
  type        = bool
  default     = false
}

