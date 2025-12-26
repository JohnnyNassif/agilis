output "sentinel_workspace_id" {
  description = "ID of the Sentinel-enabled Log Analytics workspace."
  value       = var.log_analytics_workspace_id
}

output "data_connector_ids" {
  description = "Map of data connector names to their IDs."
  value = {
    azure_activity  = var.enable_azure_activity_connector ? azurerm_sentinel_data_connector_azure_active_directory.activity_log[0].id : null
    security_center = var.enable_security_center_connector ? azurerm_sentinel_data_connector_azure_security_center.security_center[0].id : null
    # NOTE: Key Vault and Storage Account logs are collected via diagnostic settings, not Sentinel data connectors
    # These services don't have dedicated Terraform resources for Sentinel data connectors
  }
}

output "analytics_rule_ids" {
  description = "Map of analytics rule names to their IDs."
  value = {
    keyvault_failed_auth   = var.enable_keyvault_failed_auth_rule ? azurerm_sentinel_alert_rule_scheduled.keyvault_failed_auth[0].id : null
    policy_violations      = var.enable_policy_violation_rule ? azurerm_sentinel_alert_rule_scheduled.policy_violations[0].id : null
    storage_unusual_access = var.enable_storage_unusual_access_rule ? azurerm_sentinel_alert_rule_scheduled.storage_unusual_access[0].id : null
    cosmos_unusual_access  = var.enable_cosmos_unusual_access_rule ? azurerm_sentinel_alert_rule_scheduled.cosmos_unusual_access[0].id : null
    frontdoor_waf_blocked  = var.enable_frontdoor_waf_rule && var.frontdoor_profile_id != null ? azurerm_sentinel_alert_rule_scheduled.frontdoor_waf_blocked[0].id : null
    app_service_failed     = var.enable_app_service_failed_requests_rule && var.app_service_id != null ? azurerm_sentinel_alert_rule_scheduled.app_service_failed_requests[0].id : null
  }
}

