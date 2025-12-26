output "action_group_id" {
  description = "ID of the security alerts action group."
  value       = azurerm_monitor_action_group.security.id
}

output "action_group_name" {
  description = "Name of the security alerts action group."
  value       = azurerm_monitor_action_group.security.name
}

output "alert_rule_ids" {
  description = "Map of alert rule names to their IDs."
  value = {
    keyvault_failed_auth   = var.enable_keyvault_auth_alerts ? azurerm_monitor_scheduled_query_rules_alert.keyvault_failed_auth[0].id : null
    policy_violations      = var.enable_policy_violation_alerts ? azurerm_monitor_scheduled_query_rules_alert.policy_violations[0].id : null
    frontdoor_waf_blocked  = var.enable_frontdoor_waf_alerts && var.frontdoor_profile_id != null ? azurerm_monitor_scheduled_query_rules_alert.frontdoor_waf_blocked[0].id : null
    storage_unusual_access = var.enable_storage_access_alerts && var.storage_account_id != null ? azurerm_monitor_scheduled_query_rules_alert.storage_unusual_access[0].id : null
    cosmos_unusual_access  = var.enable_cosmos_access_alerts && var.cosmos_account_id != null ? azurerm_monitor_scheduled_query_rules_alert.cosmos_unusual_access[0].id : null
    nsg_denied_traffic     = var.enable_nsg_alerts && var.nsg_ids != null && length(var.nsg_ids) > 0 ? azurerm_monitor_scheduled_query_rules_alert.nsg_denied_traffic[0].id : null
    app_service_failed     = var.enable_app_service_alerts && var.app_service_id != null ? azurerm_monitor_scheduled_query_rules_alert.app_service_failed_requests[0].id : null
  }
}

