output "hipaa_initiative_assignment_id" {
  description = "ID of the HIPAA compliance initiative assignment (null if initiative not available or disabled)."
  value       = var.enable_hipaa_initiative && local.hipaa_initiative_id != null ? (var.management_group_id != null ? try(azurerm_management_group_policy_assignment.hipaa_initiative[0].id, null) : try(azurerm_subscription_policy_assignment.hipaa_initiative[0].id, null)) : null
}

output "policy_definitions" {
  description = "Map of custom policy definition IDs."
  value = var.enable_custom_policies ? {
    storage_private_endpoint          = azurerm_policy_definition.storage_private_endpoint[0].id
    keyvault_private_endpoint         = azurerm_policy_definition.keyvault_private_endpoint[0].id
    cosmos_private_endpoint           = azurerm_policy_definition.cosmos_private_endpoint[0].id
    storage_infrastructure_encryption = azurerm_policy_definition.storage_infrastructure_encryption[0].id
    diagnostic_settings               = var.log_analytics_workspace_id != null ? azurerm_policy_definition.diagnostic_settings[0].id : null
  } : {}
}

output "policy_assignments" {
  description = "Map of policy assignment IDs."
  value = var.enable_custom_policies ? {
    storage_private_endpoint          = var.management_group_id != null ? azurerm_management_group_policy_assignment.storage_private_endpoint[0].id : azurerm_subscription_policy_assignment.storage_private_endpoint[0].id
    keyvault_private_endpoint         = var.management_group_id != null ? azurerm_management_group_policy_assignment.keyvault_private_endpoint[0].id : azurerm_subscription_policy_assignment.keyvault_private_endpoint[0].id
    cosmos_private_endpoint           = var.management_group_id != null ? azurerm_management_group_policy_assignment.cosmos_private_endpoint[0].id : azurerm_subscription_policy_assignment.cosmos_private_endpoint[0].id
    storage_infrastructure_encryption = var.management_group_id != null ? azurerm_management_group_policy_assignment.storage_infrastructure_encryption[0].id : azurerm_subscription_policy_assignment.storage_infrastructure_encryption[0].id
    diagnostic_settings               = var.log_analytics_workspace_id != null ? (var.management_group_id != null ? azurerm_management_group_policy_assignment.diagnostic_settings[0].id : azurerm_subscription_policy_assignment.diagnostic_settings[0].id) : null
  } : {}
}

