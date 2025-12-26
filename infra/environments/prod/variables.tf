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

variable "app_service_enable_ip_restrictions" {
  description = "Enable IP restrictions on App Service in prod to only allow Front Door access (blocks direct Internet access). REQUIRED for HIPAA compliance."
  type        = bool
  default     = true
}

variable "storage_account_replication_type" {
  description = "Replication type for prod storage."
  type        = string
  default     = "GRS" # Geo-redundant for production
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

variable "storage_enable_infrastructure_encryption" {
  description = "Enable infrastructure encryption (double encryption) for Storage Account in prod. Required for HIPAA compliance."
  type        = bool
  default     = true
}

variable "disable_public_access_automatically" {
  description = "Automatically disable public network access for Storage Account, Key Vault, and Cosmos DB after all resources are created. REQUIRED for production/HIPAA compliance."
  type        = bool
  default     = true
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
  default     = true # Enabled for production
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

# Azure Front Door with WAF Configuration (MANDATORY for HIPAA compliance)
variable "frontdoor_enabled" {
  description = "Azure Front Door with WAF is MANDATORY for HIPAA compliance. This variable is kept for compatibility but Front Door is always enabled."
  type        = bool
  default     = true
}

variable "frontdoor_sku_name" {
  description = "SKU name for Front Door in prod (Standard_AzureFrontDoor or Premium_AzureFrontDoor)."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "frontdoor_waf_mode" {
  description = "WAF mode in prod: Detection (log only) or Prevention (block requests)."
  type        = string
  default     = "Prevention"
}

variable "frontdoor_waf_default_rule_set_action" {
  description = "Action for Microsoft Default Rule Set in prod (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
}

variable "frontdoor_waf_bot_rule_set_action" {
  description = "Action for Bot Manager Rule Set in prod (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
}

variable "frontdoor_custom_domain_name" {
  description = "Custom domain name for Front Door in prod (optional, e.g., api.example.com)."
  type        = string
  default     = null
}

variable "frontdoor_health_probe_path" {
  description = "Path for Front Door health probe requests in prod."
  type        = string
  default     = "/"
}

variable "frontdoor_route_patterns" {
  description = "URL patterns to match for Front Door routing in prod."
  type        = list(string)
  default     = ["/*"]
}

# Azure Policy Variables
variable "policy_enable_hipaa_initiative" {
  description = "Enable Azure HIPAA/HITRUST compliance policy initiative assignment in prod."
  type        = bool
  default     = true
}

variable "policy_enable_custom_policies" {
  description = "Enable custom HIPAA-specific policy assignments in prod."
  type        = bool
  default     = true
}

variable "policy_management_group_id" {
  description = "Optional management group ID for policy assignment in prod. If not provided, policies are assigned at subscription level."
  type        = string
  default     = null
}

# Security Monitoring Alerts Configuration
variable "security_alerts_email_addresses" {
  description = "List of email addresses to receive security alerts in prod."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_numbers" {
  description = "List of SMS phone numbers to receive security alerts in prod."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_country_code" {
  description = "Country code for SMS alerts in prod."
  type        = string
  default     = "1"
}

variable "security_alerts_webhook_urls" {
  description = "List of webhook URLs to receive security alerts in prod."
  type        = list(string)
  default     = []
}

variable "security_alerts_severity" {
  description = "Severity level for security alerts in prod (0-4)."
  type        = number
  default     = 0
}

variable "security_alerts_frequency_minutes" {
  description = "Frequency in minutes to evaluate security alert queries in prod."
  type        = number
  default     = 5
}

variable "security_alerts_time_window_minutes" {
  description = "Time window in minutes to query logs for security alerts in prod."
  type        = number
  default     = 15
}

variable "security_alerts_enable_keyvault_auth" {
  description = "Enable Key Vault authentication alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_policy_violations" {
  description = "Enable policy violation alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_frontdoor_waf" {
  description = "Enable Front Door WAF alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_storage_access" {
  description = "Enable Storage Account access alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_cosmos_access" {
  description = "Enable Cosmos DB access alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_nsg" {
  description = "Enable NSG alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_enable_app_service" {
  description = "Enable App Service alerts in prod."
  type        = bool
  default     = true
}

variable "security_alerts_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed auth alerts in prod."
  type        = number
  default     = 5
}

variable "security_alerts_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests in prod."
  type        = number
  default     = 10
}

variable "security_alerts_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for Storage unusual access alerts in prod."
  type        = number
  default     = 1000
}

variable "security_alerts_cosmos_unusual_access_threshold" {
  description = "Threshold for Cosmos DB unusual access alerts in prod."
  type        = number
  default     = 100
}

variable "security_alerts_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB RU alerts in prod."
  type        = number
  default     = 1000
}

variable "security_alerts_nsg_denied_traffic_threshold" {
  description = "Threshold for NSG denied traffic alerts in prod."
  type        = number
  default     = 100
}

variable "security_alerts_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests alerts in prod."
  type        = number
  default     = 50
}

# Azure Sentinel Variables
variable "sentinel_enable_azure_activity_connector" {
  description = "Enable Azure Activity Log data connector for Sentinel in prod."
  type        = bool
  default     = false
}

variable "sentinel_enable_security_center_connector" {
  description = "Enable Azure Security Center data connector for Sentinel in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_key_vault_connector" {
  description = "Enable Azure Key Vault data connector for Sentinel in prod."
  type        = bool
  default     = false
}

variable "sentinel_enable_storage_connector" {
  description = "Enable Azure Storage Account data connector for Sentinel in prod."
  type        = bool
  default     = false
}

variable "sentinel_enable_keyvault_failed_auth_rule" {
  description = "Enable Key Vault failed auth analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_policy_violation_rule" {
  description = "Enable Policy violation analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_storage_unusual_access_rule" {
  description = "Enable Storage unusual access analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_cosmos_unusual_access_rule" {
  description = "Enable Cosmos DB unusual access analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_frontdoor_waf_rule" {
  description = "Enable Front Door WAF analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_enable_app_service_failed_requests_rule" {
  description = "Enable App Service failed requests analytics rule in prod."
  type        = bool
  default     = true
}

variable "sentinel_alert_frequency_minutes" {
  description = "Frequency in minutes to evaluate Sentinel analytics rules in prod."
  type        = number
  default     = 5
}

variable "sentinel_alert_time_window_minutes" {
  description = "Time window in minutes to query logs for Sentinel analytics rules in prod."
  type        = number
  default     = 15
}

variable "sentinel_enable_event_grouping" {
  description = "Enable event grouping for Sentinel analytics rules in prod."
  type        = bool
  default     = true
}

variable "sentinel_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed auth Sentinel alerts in prod."
  type        = number
  default     = 5
}

variable "sentinel_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for Storage unusual access Sentinel alerts in prod."
  type        = number
  default     = 1000
}

variable "sentinel_cosmos_unusual_access_threshold" {
  description = "Threshold for Cosmos DB unusual access Sentinel alerts in prod."
  type        = number
  default     = 100
}

variable "sentinel_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB RU Sentinel alerts in prod."
  type        = number
  default     = 1000
}

variable "sentinel_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests Sentinel alerts in prod."
  type        = number
  default     = 10
}

variable "sentinel_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests Sentinel alerts in prod."
  type        = number
  default     = 50
}

variable "sentinel_enable_customer_managed_key" {
  description = "Enable customer-managed key encryption for Sentinel in prod."
  type        = bool
  default     = false
}

# RBAC Module Configuration
variable "rbac_enable_admin_users" {
  description = "Enable admin user RBAC assignments in prod."
  type        = bool
  default     = true
}

variable "rbac_enable_current_user_access" {
  description = "Enable current user RBAC access in prod (set to false for production)."
  type        = bool
  default     = false
}

variable "rbac_admin_user_principal_ids" {
  description = "List of admin user principal IDs for RBAC assignments in prod."
  type        = list(string)
  default     = []
}

# Static Web App Configuration
variable "static_web_app_sku_tier" {
  description = "SKU tier for Static Web App in prod (Free or Standard)."
  type        = string
  default     = "Standard"
}

variable "static_web_app_sku_size" {
  description = "SKU size for Static Web App in prod (Free or Standard)."
  type        = string
  default     = "Standard"
}

variable "static_web_app_app_settings" {
  description = "App settings (environment variables) for Static Web App in prod."
  type        = map(string)
  default     = {}
}

variable "static_web_app_custom_domain_name" {
  description = "Custom domain name for Static Web App in prod (optional)."
  type        = string
  default     = null
}
