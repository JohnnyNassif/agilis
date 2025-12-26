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

variable "bastion_subnet_cidr" {
  description = "CIDR block allocated for Azure Bastion subnet (minimum /27 = 32 IPs)."
  type        = string
  default     = "10.10.3.0/27"
}

variable "bastion_vm_subnet_cidr" {
  description = "CIDR block allocated for Windows VM subnet (cannot use app subnet - it's delegated to App Service)."
  type        = string
  default     = "10.10.4.0/24"
}

variable "bastion_enabled" {
  description = "Enable Azure Bastion with Windows jump VM."
  type        = bool
  default     = false
}

variable "bastion_vm_size" {
  description = "Size of the Windows jump VM (e.g., Standard_B1s)."
  type        = string
  default     = "Standard_B1s"
}

variable "bastion_vm_admin_username" {
  description = "Administrator username for Windows jump VM."
  type        = string
  default     = "azureadmin"
}

variable "bastion_vm_admin_password" {
  description = "Administrator password for Windows jump VM (must meet complexity requirements)."
  type        = string
  sensitive   = true
  default     = null
}

variable "bastion_auto_shutdown_enabled" {
  description = "Enable auto-shutdown schedule for the jump VM."
  type        = bool
  default     = true
}

variable "bastion_auto_shutdown_time" {
  description = "Time for auto-shutdown (24-hour format, e.g., '1800' for 6 PM)."
  type        = string
  default     = "1800"
}

variable "bastion_auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown schedule."
  type        = string
  default     = "UTC"
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

variable "app_service_enable_ip_restrictions" {
  description = "Enable IP restrictions on App Service to only allow Front Door access (blocks direct Internet access). Set to true for production to enforce Front Door-only access."
  type        = bool
  default     = false
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

variable "storage_enable_infrastructure_encryption" {
  description = "Enable infrastructure encryption (double encryption) for Storage Account. Required for HIPAA compliance. When enabled, data is encrypted twice - once at the service level and once at the infrastructure level."
  type        = bool
  default     = true
}

variable "disable_public_access_automatically" {
  description = "Automatically disable public network access for Storage Account, Key Vault, and Cosmos DB after all resources are created. Set to true for production/HIPAA compliance. When false, public access remains enabled (dev/testing only)."
  type        = bool
  default     = false
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

variable "key_vault_additional_rbac_assignments" {
  description = "List of additional RBAC role assignments for Key Vault. Format: [{ principal_id = \"...\", role_definition_name = \"Key Vault Secrets User\" }]"
  type = list(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = []
}

# Azure Front Door with WAF Configuration (MANDATORY for HIPAA compliance)
# Front Door is required to protect App Service from direct Internet access
# Note: This variable is kept for backward compatibility but Front Door is always enabled
variable "frontdoor_enabled" {
  description = "Azure Front Door with WAF is MANDATORY for HIPAA compliance. This variable is kept for compatibility but Front Door is always enabled."
  type        = bool
  default     = true
  validation {
    condition     = var.frontdoor_enabled == true
    error_message = "Front Door with WAF is MANDATORY for HIPAA compliance. frontdoor_enabled must be true."
  }
}

variable "frontdoor_sku_name" {
  description = "SKU name for Front Door (Standard_AzureFrontDoor or Premium_AzureFrontDoor)."
  type        = string
  default     = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.frontdoor_sku_name)
    error_message = "Front Door SKU must be 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "frontdoor_waf_mode" {
  description = "WAF mode: Detection (log only) or Prevention (block requests)."
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.frontdoor_waf_mode)
    error_message = "WAF mode must be either 'Detection' or 'Prevention'."
  }
}

variable "frontdoor_waf_default_rule_set_action" {
  description = "Action for Microsoft Default Rule Set (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
  validation {
    condition     = contains(["Block", "Log", "Redirect"], var.frontdoor_waf_default_rule_set_action)
    error_message = "WAF default rule set action must be 'Block', 'Log', or 'Redirect'."
  }
}

variable "frontdoor_waf_bot_rule_set_action" {
  description = "Action for Bot Manager Rule Set (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
  validation {
    condition     = contains(["Block", "Log", "Redirect"], var.frontdoor_waf_bot_rule_set_action)
    error_message = "WAF bot rule set action must be 'Block', 'Log', or 'Redirect'."
  }
}

variable "frontdoor_custom_domain_name" {
  description = "Custom domain name for Front Door (optional, e.g., api.example.com). Leave null to use default Front Door hostname."
  type        = string
  default     = null
}

variable "frontdoor_health_probe_path" {
  description = "Path for Front Door health probe requests."
  type        = string
  default     = "/"
}

variable "frontdoor_route_patterns" {
  description = "URL patterns to match for Front Door routing (legacy - now handled automatically: /api/* → backend, /* → frontend)."
  type        = list(string)
  default     = ["/*"]
}

# ============================================================================
# Static Web App Variables
# ============================================================================

variable "static_web_app_sku_tier" {
  description = "SKU tier for Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku_tier)
    error_message = "Static Web App SKU tier must be 'Free' or 'Standard'."
  }
}

variable "static_web_app_sku_size" {
  description = "SKU size for Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku_size)
    error_message = "Static Web App SKU size must be 'Free' or 'Standard'."
  }
}

variable "static_web_app_app_settings" {
  description = "App settings (environment variables) for Static Web App (e.g., API endpoint URLs)."
  type        = map(string)
  default     = {}
}

variable "static_web_app_custom_domain_name" {
  description = "Custom domain name for Static Web App (optional, e.g., app.example.com)."
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
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_whiteboard_sku_tier)
    error_message = "Whiteboard Static Web App SKU tier must be 'Free' or 'Standard'."
  }
}

variable "static_web_app_whiteboard_sku_size" {
  description = "SKU size for Whiteboard Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_whiteboard_sku_size)
    error_message = "Whiteboard Static Web App SKU size must be 'Free' or 'Standard'."
  }
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
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_telehealth_sku_tier)
    error_message = "Telehealth Static Web App SKU tier must be 'Free' or 'Standard'."
  }
}

variable "static_web_app_telehealth_sku_size" {
  description = "SKU size for Telehealth Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_telehealth_sku_size)
    error_message = "Telehealth Static Web App SKU size must be 'Free' or 'Standard'."
  }
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

# ============================================================================
# Azure Policy Variables
# ============================================================================

variable "policy_enable_hipaa_initiative" {
  description = "Enable Azure HIPAA/HITRUST compliance policy initiative assignment."
  type        = bool
  default     = true
}

variable "policy_enable_custom_policies" {
  description = "Enable custom HIPAA-specific policy assignments (private endpoints, encryption, diagnostic settings)."
  type        = bool
  default     = true
}

variable "policy_management_group_id" {
  description = "Optional management group ID for policy assignment. If not provided, policies are assigned at subscription level."
  type        = string
  default     = null
}

# ============================================================================
# Security Monitoring Alerts Configuration
# ============================================================================

variable "security_alerts_email_addresses" {
  description = "List of email addresses to receive security alerts."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_numbers" {
  description = "List of SMS phone numbers to receive security alerts (digits only, no formatting)."
  type        = list(string)
  default     = []
}

variable "security_alerts_sms_country_code" {
  description = "Country code for SMS alerts (e.g., '1' for US)."
  type        = string
  default     = "1"
}

variable "security_alerts_webhook_urls" {
  description = "List of webhook URLs to receive security alerts (e.g., Slack, Teams, PagerDuty)."
  type        = list(string)
  default     = []
}

variable "security_alerts_severity" {
  description = "Severity level for alerts (0-4, where 0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)."
  type        = number
  default     = 1
  validation {
    condition     = var.security_alerts_severity >= 0 && var.security_alerts_severity <= 4
    error_message = "Security alerts severity must be between 0 and 4."
  }
}

variable "security_alerts_frequency_minutes" {
  description = "Frequency in minutes to evaluate security alert queries."
  type        = number
  default     = 5
}

variable "security_alerts_time_window_minutes" {
  description = "Time window in minutes to query logs for security alerts."
  type        = number
  default     = 15
}

variable "security_alerts_enable_keyvault_auth" {
  description = "Enable alerts for Key Vault failed authentication attempts."
  type        = bool
  default     = true
}

variable "security_alerts_enable_policy_violations" {
  description = "Enable alerts for Azure Policy compliance violations."
  type        = bool
  default     = true
}

variable "security_alerts_enable_frontdoor_waf" {
  description = "Enable alerts for Front Door WAF blocked requests."
  type        = bool
  default     = true
}

variable "security_alerts_enable_storage_access" {
  description = "Enable alerts for unusual Storage Account access patterns."
  type        = bool
  default     = true
}

variable "security_alerts_enable_cosmos_access" {
  description = "Enable alerts for unusual Cosmos DB access patterns."
  type        = bool
  default     = true
}

variable "security_alerts_enable_nsg" {
  description = "Enable alerts for NSG denied traffic."
  type        = bool
  default     = true
}

variable "security_alerts_enable_app_service" {
  description = "Enable alerts for App Service failed requests."
  type        = bool
  default     = true
}

variable "security_alerts_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed authentication attempts to trigger alert."
  type        = number
  default     = 5
}

variable "security_alerts_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests to trigger alert."
  type        = number
  default     = 10
}

variable "security_alerts_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for unusual Storage Account data transfer to trigger alert."
  type        = number
  default     = 1000 # 1 GB
}

variable "security_alerts_cosmos_unusual_access_threshold" {
  description = "Threshold for unusual Cosmos DB access requests to trigger alert."
  type        = number
  default     = 100
}

variable "security_alerts_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB request units (RU) to consider unusual."
  type        = number
  default     = 1000
}

variable "security_alerts_nsg_denied_traffic_threshold" {
  description = "Threshold for NSG denied packets to trigger alert."
  type        = number
  default     = 100
}

variable "security_alerts_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests (4xx/5xx) to trigger alert."
  type        = number
  default     = 50
}

# ============================================================================
# Azure Sentinel Variables
# ============================================================================

variable "sentinel_enable_azure_activity_connector" {
  description = "Enable Azure Activity Log data connector for Sentinel."
  type        = bool
  default     = true
}

variable "sentinel_enable_security_center_connector" {
  description = "Enable Azure Security Center data connector for Sentinel."
  type        = bool
  default     = true
}

variable "sentinel_enable_key_vault_connector" {
  description = "Enable Azure Key Vault data connector for Sentinel."
  type        = bool
  default     = true
}

variable "sentinel_enable_storage_connector" {
  description = "Enable Azure Storage Account data connector for Sentinel."
  type        = bool
  default     = true
}

variable "sentinel_enable_keyvault_failed_auth_rule" {
  description = "Enable Sentinel analytics rule for Key Vault failed authentication attempts."
  type        = bool
  default     = true
}

variable "sentinel_enable_policy_violation_rule" {
  description = "Enable Sentinel analytics rule for Azure Policy compliance violations."
  type        = bool
  default     = true
}

variable "sentinel_enable_storage_unusual_access_rule" {
  description = "Enable Sentinel analytics rule for unusual Storage Account access patterns."
  type        = bool
  default     = true
}

variable "sentinel_enable_cosmos_unusual_access_rule" {
  description = "Enable Sentinel analytics rule for unusual Cosmos DB access patterns."
  type        = bool
  default     = true
}

variable "sentinel_enable_frontdoor_waf_rule" {
  description = "Enable Sentinel analytics rule for Front Door WAF blocked requests."
  type        = bool
  default     = true
}

variable "sentinel_enable_app_service_failed_requests_rule" {
  description = "Enable Sentinel analytics rule for App Service failed requests."
  type        = bool
  default     = true
}

variable "sentinel_alert_frequency_minutes" {
  description = "Frequency in minutes to evaluate Sentinel analytics rule queries."
  type        = number
  default     = 5
}

variable "sentinel_alert_time_window_minutes" {
  description = "Time window in minutes to query logs for Sentinel analytics rules."
  type        = number
  default     = 15
}

variable "sentinel_enable_event_grouping" {
  description = "Enable event grouping for Sentinel analytics rules (creates one alert per result)."
  type        = bool
  default     = true
}

variable "sentinel_keyvault_failed_auth_threshold" {
  description = "Threshold for Key Vault failed authentication attempts to trigger Sentinel alert."
  type        = number
  default     = 5
}

variable "sentinel_storage_unusual_access_threshold_mb" {
  description = "Threshold in MB for unusual Storage Account data transfer to trigger Sentinel alert."
  type        = number
  default     = 1000 # 1 GB
}

variable "sentinel_cosmos_unusual_access_threshold" {
  description = "Threshold for unusual Cosmos DB access requests to trigger Sentinel alert."
  type        = number
  default     = 100
}

variable "sentinel_cosmos_unusual_ru_threshold" {
  description = "Threshold for Cosmos DB request units (RU) to consider unusual for Sentinel alerts."
  type        = number
  default     = 1000
}

variable "sentinel_frontdoor_waf_blocked_threshold" {
  description = "Threshold for Front Door WAF blocked requests to trigger Sentinel alert."
  type        = number
  default     = 10
}

variable "sentinel_app_service_failed_requests_threshold" {
  description = "Threshold for App Service failed requests (4xx/5xx) to trigger Sentinel alert."
  type        = number
  default     = 50
}

variable "sentinel_enable_customer_managed_key" {
  description = "Enable customer-managed key encryption for Sentinel (requires Key Vault with key)."
  type        = bool
  default     = false
}

# ============================================================================
# RBAC Module Variables
# ============================================================================

variable "rbac_admin_user_principal_ids" {
  description = "List of admin user principal IDs (Object IDs) for client admin access. Supports up to 3 admin users. Set this for production (client account), leave empty for development (personal account)."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.rbac_admin_user_principal_ids) <= 3
    error_message = "Maximum 3 admin users are supported."
  }
}

variable "rbac_enable_admin_users" {
  description = "Enable RBAC assignments for admin users (client admins). Set to true for production (client account), false for development (personal account)."
  type        = bool
  default     = false
}

variable "rbac_enable_current_user_access" {
  description = "Enable RBAC assignment for current user (useful for development/testing in personal Azure accounts). Set to false for production (client account)."
  type        = bool
  default     = true
}
