locals {
  name_prefix = lower(format("%s-%s", var.common_prefix, var.environment))

  default_tags = {
    project = "agilis-azure-hipaa"
    env     = var.environment
    owner   = "agilis"
  }

  tags = merge(local.default_tags, var.tags)

  resource_group_name = format("rg-%s-core", local.name_prefix)
}

module "resource_group" {
  source = "./modules/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  vnet_address_space  = var.vnet_address_space
  app_subnet_cidr     = var.app_subnet_cidr
  data_subnet_cidr    = var.data_subnet_cidr
  tags                = local.tags
}

# Create Key Vault FIRST (no dependencies) to grant RBAC permissions early
# This allows RBAC to propagate naturally while Cosmos DB and Storage Account are being created
# Secrets will be created separately after Cosmos/Storage are ready
module "key_vault" {
  source = "./modules/key_vault"

  name_prefix                = local.name_prefix
  location                   = var.location
  resource_group_name        = module.resource_group.resource_group_name
  tenant_id                  = var.tenant_id
  data_subnet_id             = module.network.data_subnet_id
  virtual_network_id         = module.network.vnet_id
  app_service_principal_id   = null # Will be set after App Service is created
  terraform_principal_id     = var.terraform_principal_id
  additional_rbac_assignments = var.key_vault_additional_rbac_assignments
  enable_current_user_access = var.rbac_enable_current_user_access
  sku_name                   = var.key_vault_sku_name
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  cosmos_connection_string_secret_name = var.key_vault_cosmos_secret_name
  storage_account_key_secret_name      = var.key_vault_storage_key_secret_name
  storage_account_name_secret_name     = var.key_vault_storage_name_secret_name
  tags                       = local.tags
  # No secrets created here - they're created separately after Cosmos/Storage are ready
}

# Create Cosmos DB second (no dependencies, but creation takes 5-10 minutes)
# This gives RBAC time to propagate naturally while Cosmos DB is being created
module "cosmos_mongo" {
  source = "./modules/cosmos_mongo"

  name_prefix                   = local.name_prefix
  location                      = var.location
  resource_group_name           = module.resource_group.resource_group_name
  data_subnet_id                = module.network.data_subnet_id
  virtual_network_id            = module.network.vnet_id
  account_name_suffix           = var.cosmos_account_name_suffix
  tags                          = local.tags
  mongo_database_name           = var.cosmos_mongo_database_name
  mongo_collection_name         = var.cosmos_mongo_collection_name
  mongo_collection_shard_key    = var.cosmos_mongo_collection_shard_key
  mongo_database_max_throughput = var.cosmos_mongo_database_max_throughput
  consistency_level             = var.cosmos_consistency_level
  enable_automatic_failover     = var.cosmos_enable_automatic_failover
  free_tier_enabled             = var.cosmos_free_tier_enabled
  server_version                = var.cosmos_server_version
  analytical_storage_enabled    = var.cosmos_analytical_storage_enabled
  continuous_backup_enabled     = var.cosmos_continuous_backup_enabled
}

# Create Storage Account third (no dependencies, but creation takes 2-5 minutes)
# This gives RBAC additional time to propagate naturally while Storage Account is being created
module "storage" {
  source = "./modules/storage"

  name_prefix                      = local.name_prefix
  location                         = var.location
  resource_group_name              = module.resource_group.resource_group_name
  data_subnet_id                   = module.network.data_subnet_id
  virtual_network_id               = module.network.vnet_id
  account_replication_type         = var.storage_account_replication_type
  account_tier                     = var.storage_account_tier
  container_names                  = var.storage_container_names
  enable_infrastructure_encryption = var.storage_enable_infrastructure_encryption
  tags                             = local.tags
}

# Data source to get Storage account key for Key Vault secrets
data "azurerm_storage_account" "storage" {
  name                = module.storage.storage_account_name
  resource_group_name = module.resource_group.resource_group_name
}

# Construct Cosmos DB MongoDB connection string (needed for Key Vault secrets)
locals {
  cosmos_connection_string = "mongodb://${module.cosmos_mongo.account_name}:${module.cosmos_mongo.primary_key}@${module.cosmos_mongo.account_name}.mongo.cosmos.azure.net:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@${module.cosmos_mongo.account_name}@"

  # Construct app_settings with Key Vault references and Application Insights
  # Key Vault and Monitoring must exist before App Service
  app_service_app_settings_with_vault = merge(
    var.app_service_app_settings,
    {
      # Key Vault references (Key Vault is created before App Service)
      COSMOS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${module.key_vault.key_vault_uri}secrets/${var.key_vault_cosmos_secret_name}/)"
      STORAGE_ACCOUNT_KEY      = "@Microsoft.KeyVault(SecretUri=${module.key_vault.key_vault_uri}secrets/${var.key_vault_storage_key_secret_name}/)"
      STORAGE_ACCOUNT_NAME     = "@Microsoft.KeyVault(SecretUri=${module.key_vault.key_vault_uri}secrets/${var.key_vault_storage_name_secret_name}/)"
      # Application Insights (Monitoring is created before App Service)
      APPINSIGHTS_INSTRUMENTATIONKEY        = module.monitoring.application_insights_instrumentation_key
      APPLICATIONINSIGHTS_CONNECTION_STRING = module.monitoring.application_insights_connection_string
    }
  )
}

# Create Key Vault secrets AFTER Cosmos and Storage are ready
# By this time, RBAC permissions have propagated naturally (Cosmos/Storage creation takes 5-10+ minutes)
# This gives RBAC time to propagate while Cosmos/Storage are being created
# Note: We depend on the modules themselves rather than individual RBAC assignments
# because Terraform requires static lists for depends_on, and RBAC propagation happens naturally
resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = var.key_vault_cosmos_secret_name
  value        = local.cosmos_connection_string
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    module.cosmos_mongo,
    module.storage,
    module.key_vault
  ]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = var.key_vault_storage_key_secret_name
  value        = data.azurerm_storage_account.storage.primary_access_key
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    module.storage,
    module.key_vault
  ]
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = var.key_vault_storage_name_secret_name
  value        = module.storage.storage_account_name
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    module.storage,
    module.key_vault
  ]
}

# Create Monitoring fourth (Log Analytics + Application Insights - no dependencies)
# Only diagnostic settings depend on other resources, which are created conditionally
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  retention_in_days   = var.log_analytics_retention_in_days
  app_service_id      = null # Will be set after App Service is created
  cosmos_account_id   = null # Will be set after Cosmos is created
  storage_account_id  = null # Will be set after Storage is created
  key_vault_id        = null # Will be set after Key Vault is created
  tags                = local.tags
}

# Create App Service fifth (main backend API with Key Vault references and Application Insights)
module "app_service" {
  source = "./modules/app_service"

  name_prefix               = local.name_prefix
  location                  = var.location
  resource_group_name       = module.resource_group.resource_group_name
  app_service_sku_name      = var.app_service_sku_name
  app_service_plan_capacity = var.app_service_plan_capacity
  always_on                 = var.app_service_always_on
  name_suffix               = var.app_service_name_suffix
  app_settings              = local.app_service_app_settings_with_vault # Includes Key Vault refs + App Insights
  connection_strings        = var.app_service_connection_strings
  subnet_id                 = module.network.app_subnet_id
  node_version              = var.app_service_node_version
  tags                      = local.tags

  depends_on = [
    module.key_vault, # Key Vault must exist for app_settings references
    module.monitoring # Application Insights must exist for app_settings
  ]
}

# Create App Service for Whiteboard backend API (low-tier for minimal load)
module "app_service_whiteboard" {
  source = "./modules/app_service"

  name_prefix               = local.name_prefix
  location                  = var.location
  resource_group_name       = module.resource_group.resource_group_name
  app_service_sku_name      = var.app_service_whiteboard_sku_name
  app_service_plan_capacity = var.app_service_whiteboard_plan_capacity
  always_on                 = var.app_service_whiteboard_always_on
  name_suffix               = "-white-board"
  app_settings              = local.app_service_app_settings_with_vault # Same Key Vault refs + App Insights
  connection_strings        = []
  subnet_id                 = module.network.app_subnet_id
  node_version              = var.app_service_node_version
  tags                      = merge(local.tags, { component = "whiteboard-backend" })

  depends_on = [
    module.key_vault,
    module.monitoring
  ]
}

# Create App Service for Telehealth backend API (low-tier for minimal load)
module "app_service_telehealth" {
  source = "./modules/app_service"

  name_prefix               = local.name_prefix
  location                  = var.location
  resource_group_name       = module.resource_group.resource_group_name
  app_service_sku_name      = var.app_service_telehealth_sku_name
  app_service_plan_capacity = var.app_service_telehealth_plan_capacity
  always_on                 = var.app_service_telehealth_always_on
  name_suffix               = "-telemed"
  app_settings              = local.app_service_app_settings_with_vault # Same Key Vault refs + App Insights
  connection_strings        = []
  subnet_id                 = module.network.app_subnet_id
  node_version              = var.app_service_node_version
  tags                      = merge(local.tags, { component = "telehealth-backend" })

  depends_on = [
    module.key_vault,
    module.monitoring
  ]
}

# RBAC assignments are now handled by the RBAC module (see module "rbac" below)

# Create Static Web App for frontend (Angular app - main portal)
module "static_web_app" {
  source = "./modules/static_web_app"

  name_prefix         = local.name_prefix
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  sku_tier            = var.static_web_app_sku_tier
  sku_size            = var.static_web_app_sku_size
  app_settings        = var.static_web_app_app_settings
  custom_domain_name  = var.static_web_app_custom_domain_name
  tags                = local.tags
}

# Create Static Web App for Whiteboard frontend (embedded via iframe)
module "static_web_app_whiteboard" {
  source = "./modules/static_web_app"

  name_prefix         = "${local.name_prefix}-whiteboard"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  sku_tier            = var.static_web_app_whiteboard_sku_tier
  sku_size            = var.static_web_app_whiteboard_sku_size
  app_settings        = var.static_web_app_whiteboard_app_settings
  custom_domain_name  = null # No custom domain for whiteboard (accessed via default URL)
  tags                = merge(local.tags, { component = "whiteboard-frontend" })
}

# Create Static Web App for Telehealth frontend (embedded via iframe)
module "static_web_app_telehealth" {
  source = "./modules/static_web_app"

  name_prefix         = "${local.name_prefix}-telehealth"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  sku_tier            = var.static_web_app_telehealth_sku_tier
  sku_size            = var.static_web_app_telehealth_sku_size
  app_settings        = var.static_web_app_telehealth_app_settings
  custom_domain_name  = null # No custom domain for telehealth (accessed via default URL)
  tags                = merge(local.tags, { component = "telehealth-frontend" })
}

# Update Monitoring diagnostic settings after all resources are created
# Application Insights and Log Analytics are created independently, but diagnostic settings need resource IDs
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count                      = 1
  name                       = format("diag-%s-app", local.name_prefix)
  target_resource_id         = module.app_service.app_service_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    module.app_service,
    module.monitoring
  ]
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                      = 1
  name                       = format("diag-%s-cosmos", local.name_prefix)
  target_resource_id         = module.cosmos_mongo.account_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "PartitionKeyRUConsumption"
  }

  enabled_log {
    category = "ControlPlaneRequests"
  }

  metric {
    category = "Requests"
    enabled  = true
  }

  metric {
    category = "SLI"
    enabled  = true
  }

  depends_on = [
    module.cosmos_mongo,
    module.monitoring
  ]
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = 1
  name                       = format("diag-%s-storage", local.name_prefix)
  target_resource_id         = module.storage.storage_account_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # Note: Storage Account (root) diagnostic settings only support metrics, not data-plane logs.
  # Blob data-plane logs are configured below on the blob service endpoint.
  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }

  depends_on = [
    module.storage,
    module.monitoring
  ]
}

# P0.3: Storage Blob data-plane audit logs to Log Analytics (PHI file access audit)
# Enables blob read/write/delete operation logs to flow into Log Analytics (StorageBlobLogs table).
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  count                      = 1
  name                       = format("diag-%s-storage-blob", local.name_prefix)
  target_resource_id         = "${module.storage.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  depends_on = [
    module.storage,
    module.monitoring
  ]
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = 1
  name                       = format("diag-%s-kv", local.name_prefix)
  target_resource_id         = module.key_vault.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    module.key_vault,
    module.monitoring
  ]
}

# P0.4: Front Door + WAF diagnostics to Log Analytics (so WAF alerts work)
# This enables WAF logs to flow to Log Analytics for security alerts and Sentinel analytics
resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  count                      = var.frontdoor_enabled ? 1 : 0
  name                       = format("diag-%s-frontdoor", local.name_prefix)
  target_resource_id         = module.frontdoor_waf.frontdoor_profile_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # Front Door Access Logs - tracks all requests through Front Door
  enabled_log {
    category = "FrontDoorAccessLog"
  }

  # Front Door Health Probe Logs - tracks health probe requests
  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  # Front Door WAF Logs - CRITICAL for P0.4: tracks WAF blocked/allowed requests
  # This is required for security alerts/Sentinel rules that query FrontDoorWebApplicationFirewallLog
  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }

  # Front Door Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    module.frontdoor_waf,
    module.monitoring
  ]
}

# Azure Bastion with Windows Jump VM (optional, pay-as-you-go)
module "bastion" {
  count = var.bastion_enabled ? 1 : 0

  source = "./modules/bastion"

  name_prefix            = local.name_prefix
  location               = var.location
  resource_group_name    = module.resource_group.resource_group_name
  virtual_network_name   = module.network.vnet_name
  bastion_subnet_cidr    = var.bastion_subnet_cidr
  vm_subnet_cidr         = var.bastion_vm_subnet_cidr
  vm_size                = var.bastion_vm_size
  vm_admin_username      = var.bastion_vm_admin_username
  vm_admin_password      = var.bastion_vm_admin_password != null ? var.bastion_vm_admin_password : random_password.bastion_vm_password[0].result
  auto_shutdown_enabled  = var.bastion_auto_shutdown_enabled
  auto_shutdown_time     = var.bastion_auto_shutdown_time
  auto_shutdown_timezone = var.bastion_auto_shutdown_timezone
  key_vault_id           = module.key_vault.key_vault_id
  storage_account_id     = module.storage.storage_account_id
  cosmos_account_id      = module.cosmos_mongo.account_id
  tags                   = local.tags

  depends_on = [
    module.network,
    module.key_vault,
    module.storage,
    module.cosmos_mongo
  ]
}

# Generate random password for Windows VM if not provided
resource "random_password" "bastion_vm_password" {
  count   = var.bastion_enabled && var.bastion_vm_admin_password == null ? 1 : 0
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Azure Front Door with WAF (MANDATORY for HIPAA compliance)
# Front Door protects App Service from direct Internet access and provides WAF protection
# Routes frontend requests to Static Web App and API requests to App Service
module "frontdoor_waf" {
  source = "./modules/frontdoor_waf"

  name_prefix                    = local.name_prefix
  resource_group_name            = module.resource_group.resource_group_name
  sku_name                       = var.frontdoor_sku_name
  app_service_host_name          = module.app_service.default_site_hostname
  enable_static_web_app_frontend = true # Static Web App is always created, so enable frontend routing
  static_web_app_host_name       = module.static_web_app.static_web_app_default_hostname
  custom_domain_name             = var.frontdoor_custom_domain_name
  health_probe_path              = var.frontdoor_health_probe_path
  route_patterns_to_match        = var.frontdoor_route_patterns
  waf_mode                       = var.frontdoor_waf_mode
  waf_default_rule_set_action    = var.frontdoor_waf_default_rule_set_action
  waf_bot_rule_set_action        = var.frontdoor_waf_bot_rule_set_action
  tags                           = local.tags

  depends_on = [
    module.app_service,   # App Service must exist before Front Door can target it
    module.static_web_app # Static Web App must exist before Front Door can target it
  ]
}

# P0.2: Enforce Front Door–only ingress to App Service (block direct azurewebsites.net)
# This uses Azure CLI to configure IP restrictions with service tag and header validation
# Note: Terraform's azurerm_app_service doesn't support service tag + header validation directly
# IP Restrictions Script - REMOVED
# Configure App Service IP restrictions manually using the checklist in HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md
# This script was removed due to Windows/Git Bash compatibility issues

# Azure Policy for HIPAA Compliance Enforcement
# Assigns HIPAA compliance policies and custom policies for continuous compliance
module "policy" {
  source = "./modules/policy"

  name_prefix                = local.name_prefix
  resource_group_name        = module.resource_group.resource_group_name
  subscription_id            = var.subscription_id
  management_group_id        = var.policy_management_group_id
  enable_hipaa_initiative    = var.policy_enable_hipaa_initiative
  enable_custom_policies     = var.policy_enable_custom_policies
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags

  depends_on = [
    module.monitoring # Need Log Analytics Workspace for diagnostic settings policy
  ]
}

# Security Monitoring Alerts
# Creates alert rules for security events (failed auth, policy violations, network anomalies, etc.)
module "security_alerts" {
  source = "./modules/security_alerts"

  name_prefix                           = local.name_prefix
  resource_group_name                   = module.resource_group.resource_group_name
  location                              = var.location
  log_analytics_workspace_id            = module.monitoring.log_analytics_workspace_id
  frontdoor_profile_id                  = module.frontdoor_waf.frontdoor_profile_id
  storage_account_id                    = module.storage.storage_account_id
  cosmos_account_id                     = module.cosmos_mongo.account_id
  app_service_id                        = module.app_service.app_service_id
  nsg_ids                               = [module.network.app_nsg_id, module.network.data_nsg_id]
  alert_email_addresses                 = var.security_alerts_email_addresses
  alert_sms_numbers                     = var.security_alerts_sms_numbers
  alert_sms_country_code                = var.security_alerts_sms_country_code
  alert_webhook_urls                    = var.security_alerts_webhook_urls
  alert_severity                        = var.security_alerts_severity
  alert_frequency_minutes               = var.security_alerts_frequency_minutes
  alert_time_window_minutes             = var.security_alerts_time_window_minutes
  enable_keyvault_auth_alerts           = var.security_alerts_enable_keyvault_auth
  enable_policy_violation_alerts        = var.security_alerts_enable_policy_violations
  enable_frontdoor_waf_alerts           = var.security_alerts_enable_frontdoor_waf
  enable_storage_access_alerts          = var.security_alerts_enable_storage_access
  enable_cosmos_access_alerts           = var.security_alerts_enable_cosmos_access
  enable_nsg_alerts                     = var.security_alerts_enable_nsg
  enable_app_service_alerts             = var.security_alerts_enable_app_service
  keyvault_failed_auth_threshold        = var.security_alerts_keyvault_failed_auth_threshold
  frontdoor_waf_blocked_threshold       = var.security_alerts_frontdoor_waf_blocked_threshold
  storage_unusual_access_threshold_mb   = var.security_alerts_storage_unusual_access_threshold_mb
  cosmos_unusual_access_threshold       = var.security_alerts_cosmos_unusual_access_threshold
  cosmos_unusual_ru_threshold           = var.security_alerts_cosmos_unusual_ru_threshold
  nsg_denied_traffic_threshold          = var.security_alerts_nsg_denied_traffic_threshold
  app_service_failed_requests_threshold = var.security_alerts_app_service_failed_requests_threshold
  tags                                  = local.tags

  depends_on = [
    module.monitoring,    # Need Log Analytics Workspace
    module.frontdoor_waf, # Need Front Door for WAF alerts
    module.storage,       # Need Storage Account for access alerts
    module.cosmos_mongo,  # Need Cosmos DB for access alerts
    module.app_service,   # Need App Service for failed request alerts
    module.network        # Need NSGs for network alerts
  ]
}

# Azure Sentinel
# SIEM/SOAR platform for security monitoring, threat detection, and automated response
module "sentinel" {
  source = "./modules/sentinel"

  name_prefix                             = local.name_prefix
  resource_group_name                     = module.resource_group.resource_group_name
  log_analytics_workspace_id              = module.monitoring.log_analytics_workspace_id
  subscription_id                         = var.subscription_id
  tenant_id                               = var.tenant_id
  key_vault_id                            = module.key_vault.key_vault_id
  storage_account_id                      = module.storage.storage_account_id
  cosmos_account_id                       = module.cosmos_mongo.account_id
  app_service_id                          = module.app_service.app_service_id
  frontdoor_profile_id                    = module.frontdoor_waf.frontdoor_profile_id
  enable_azure_activity_connector         = var.sentinel_enable_azure_activity_connector
  enable_security_center_connector        = var.sentinel_enable_security_center_connector
  enable_key_vault_connector              = var.sentinel_enable_key_vault_connector
  enable_storage_connector                = var.sentinel_enable_storage_connector
  enable_keyvault_failed_auth_rule        = var.sentinel_enable_keyvault_failed_auth_rule
  enable_policy_violation_rule            = var.sentinel_enable_policy_violation_rule
  enable_storage_unusual_access_rule      = var.sentinel_enable_storage_unusual_access_rule
  enable_cosmos_unusual_access_rule       = var.sentinel_enable_cosmos_unusual_access_rule
  enable_frontdoor_waf_rule               = var.sentinel_enable_frontdoor_waf_rule
  enable_app_service_failed_requests_rule = var.sentinel_enable_app_service_failed_requests_rule
  alert_frequency_minutes                 = var.sentinel_alert_frequency_minutes
  alert_time_window_minutes               = var.sentinel_alert_time_window_minutes
  enable_event_grouping                   = var.sentinel_enable_event_grouping
  keyvault_failed_auth_threshold          = var.sentinel_keyvault_failed_auth_threshold
  storage_unusual_access_threshold_mb     = var.sentinel_storage_unusual_access_threshold_mb
  cosmos_unusual_access_threshold         = var.sentinel_cosmos_unusual_access_threshold
  cosmos_unusual_ru_threshold             = var.sentinel_cosmos_unusual_ru_threshold
  frontdoor_waf_blocked_threshold         = var.sentinel_frontdoor_waf_blocked_threshold
  app_service_failed_requests_threshold   = var.sentinel_app_service_failed_requests_threshold
  enable_customer_managed_key             = var.sentinel_enable_customer_managed_key
  tags                                    = local.tags

  depends_on = [
    module.monitoring,    # Need Log Analytics Workspace
    module.key_vault,     # Need Key Vault for data connector
    module.storage,       # Need Storage Account for data connector and analytics rules
    module.cosmos_mongo,  # Need Cosmos DB for analytics rules
    module.app_service,   # Need App Service for analytics rules
    module.frontdoor_waf, # Need Front Door for analytics rules
    module.policy         # Need Policy for compliance violation analytics rule
  ]
}

# ============================================================================
# RBAC Module
# ============================================================================
# Centralized RBAC role assignments for managed identities, admin users, and service principals
module "rbac" {
  source = "./modules/rbac"

  name_prefix                = local.name_prefix
  subscription_id            = var.subscription_id
  resource_group_id          = module.resource_group.resource_group_id
  key_vault_id               = module.key_vault.key_vault_id
  storage_account_id         = module.storage.storage_account_id
  cosmos_account_id          = module.cosmos_mongo.account_id
  app_service_principal_id   = module.app_service.principal_id
  bastion_enabled            = var.bastion_enabled
  bastion_vm_principal_id    = var.bastion_enabled ? module.bastion[0].vm_principal_id : null
  terraform_principal_id     = var.terraform_principal_id
  admin_user_principal_ids   = var.rbac_admin_user_principal_ids
  enable_admin_users         = var.rbac_enable_admin_users
  enable_current_user_access = var.rbac_enable_current_user_access
  tags                       = local.tags

  depends_on = [
    module.app_service,
    module.key_vault,
    module.storage,
    module.cosmos_mongo,
    module.bastion
  ]
}


# Automatically disable public access on Storage Account, Key Vault, and Cosmos DB after provisioning
# Disable Public Access Script - REMOVED
# Disable public access manually using the checklist in HIPAA_COMPLIANCE_MANUAL_CHECKLIST.md
# This script was removed due to Windows/Git Bash compatibility issues

#
# P0.3 NOTE:
# Storage data-plane auditing to Log Analytics is handled by `azurerm_monitor_diagnostic_setting.storage_blob`
# (resource-specific diagnostics on the blob service endpoint). No out-of-band CLI provisioning is required.

# Modules will be added incrementally. Each module will consume the shared
# locals above to keep naming, tagging, and retention policies consistent
# across every environment.
