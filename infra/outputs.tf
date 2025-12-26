output "resource_group_name" {
  description = "Name of the primary resource group for this environment."
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "ID of the primary resource group."
  value       = module.resource_group.resource_group_id
}

output "vnet_id" {
  description = "ID of the core virtual network."
  value       = module.network.vnet_id
}

output "app_subnet_id" {
  description = "Subnet ID for App Service integration."
  value       = module.network.app_subnet_id
}

output "data_subnet_id" {
  description = "Subnet ID reserved for private endpoints."
  value       = module.network.data_subnet_id
}

output "app_service_id" {
  description = "ID of the backend App Service."
  value       = module.app_service.app_service_id
}

output "app_service_name" {
  description = "Name of the backend App Service."
  value       = module.app_service.app_service_name
}

output "app_service_identity_principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = module.app_service.principal_id
}

output "storage_account_name" {
  description = "Storage account name."
  value       = module.storage.storage_account_name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = module.storage.primary_blob_endpoint
}

output "storage_private_endpoint_id" {
  description = "ID of the storage private endpoint."
  value       = module.storage.private_endpoint_id
}
output "cosmos_account_name" {
  description = "Cosmos DB account name."
  value       = module.cosmos_mongo.account_name
}

output "cosmos_account_endpoint" {
  description = "Cosmos DB account endpoint."
  value       = module.cosmos_mongo.account_endpoint
}

output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = module.key_vault.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.key_vault.key_vault_uri
}

output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint."
  value       = module.key_vault.private_endpoint_id
}

output "bastion_vm_name" {
  description = "Name of the Windows jump VM (if Bastion is enabled)."
  value       = var.bastion_enabled ? module.bastion[0].vm_name : null
}

output "bastion_vm_admin_username" {
  description = "Administrator username for the Windows jump VM (if Bastion is enabled)."
  value       = var.bastion_enabled ? module.bastion[0].vm_admin_username : null
}

output "bastion_vm_password" {
  description = "Auto-generated password for Windows jump VM (only if password was auto-generated and Bastion is enabled). Use 'terraform output -raw bastion_vm_password' to retrieve."
  value       = var.bastion_enabled && var.bastion_vm_admin_password == null ? random_password.bastion_vm_password[0].result : null
  sensitive   = true
}

output "bastion_name" {
  description = "Name of the Azure Bastion host (if Bastion is enabled)."
  value       = var.bastion_enabled ? module.bastion[0].bastion_name : null
}

output "frontdoor_endpoint_hostname" {
  description = "Front Door endpoint hostname (use this to access your application - Front Door is mandatory for HIPAA compliance)."
  value       = module.frontdoor_waf.frontdoor_endpoint_hostname
}

# ============================================================================
# Static Web App Outputs
# ============================================================================

output "static_web_app_id" {
  description = "ID of the Static Web App (frontend)."
  value       = module.static_web_app.static_web_app_id
}

output "static_web_app_name" {
  description = "Name of the Static Web App (frontend)."
  value       = module.static_web_app.static_web_app_name
}

output "static_web_app_default_hostname" {
  description = "Default hostname of the Static Web App (e.g., swa-agilis-dev.azurestaticapps.net)."
  value       = module.static_web_app.static_web_app_default_hostname
}

output "static_web_app_api_key" {
  description = "API key for deploying to Static Web App (sensitive - use for CI/CD deployments)."
  value       = module.static_web_app.static_web_app_api_key
  sensitive   = true
}

output "frontdoor_profile_name" {
  description = "Name of the Front Door profile (Front Door is mandatory for HIPAA compliance)."
  value       = module.frontdoor_waf.frontdoor_profile_name
}

output "frontdoor_waf_policy_name" {
  description = "Name of the WAF policy (Front Door is mandatory for HIPAA compliance)."
  value       = module.frontdoor_waf.waf_policy_name
}

output "frontdoor_custom_domain_name" {
  description = "Custom domain name configured for Front Door (if custom domain is configured)."
  value       = module.frontdoor_waf.custom_domain_name
}

# ============================================================================
# Whiteboard Static Web App Outputs
# ============================================================================

output "static_web_app_whiteboard_id" {
  description = "ID of the Whiteboard Static Web App."
  value       = module.static_web_app_whiteboard.static_web_app_id
}

output "static_web_app_whiteboard_name" {
  description = "Name of the Whiteboard Static Web App."
  value       = module.static_web_app_whiteboard.static_web_app_name
}

output "static_web_app_whiteboard_default_hostname" {
  description = "Default hostname of the Whiteboard Static Web App (for iframe embedding)."
  value       = module.static_web_app_whiteboard.static_web_app_default_hostname
}

output "static_web_app_whiteboard_api_key" {
  description = "API key for deploying to Whiteboard Static Web App (sensitive)."
  value       = module.static_web_app_whiteboard.static_web_app_api_key
  sensitive   = true
}

# ============================================================================
# Telehealth Static Web App Outputs
# ============================================================================

output "static_web_app_telehealth_id" {
  description = "ID of the Telehealth Static Web App."
  value       = module.static_web_app_telehealth.static_web_app_id
}

output "static_web_app_telehealth_name" {
  description = "Name of the Telehealth Static Web App."
  value       = module.static_web_app_telehealth.static_web_app_name
}

output "static_web_app_telehealth_default_hostname" {
  description = "Default hostname of the Telehealth Static Web App (for iframe embedding)."
  value       = module.static_web_app_telehealth.static_web_app_default_hostname
}

output "static_web_app_telehealth_api_key" {
  description = "API key for deploying to Telehealth Static Web App (sensitive)."
  value       = module.static_web_app_telehealth.static_web_app_api_key
  sensitive   = true
}

# ============================================================================
# Whiteboard App Service Outputs
# ============================================================================

output "app_service_whiteboard_id" {
  description = "ID of the Whiteboard App Service."
  value       = module.app_service_whiteboard.app_service_id
}

output "app_service_whiteboard_name" {
  description = "Name of the Whiteboard App Service."
  value       = module.app_service_whiteboard.app_service_name
}

output "app_service_whiteboard_default_hostname" {
  description = "Default hostname of the Whiteboard App Service."
  value       = module.app_service_whiteboard.default_site_hostname
}

# ============================================================================
# Telehealth App Service Outputs
# ============================================================================

output "app_service_telehealth_id" {
  description = "ID of the Telehealth App Service."
  value       = module.app_service_telehealth.app_service_id
}

output "app_service_telehealth_name" {
  description = "Name of the Telehealth App Service."
  value       = module.app_service_telehealth.app_service_name
}

output "app_service_telehealth_default_hostname" {
  description = "Default hostname of the Telehealth App Service."
  value       = module.app_service_telehealth.default_site_hostname
}

# ============================================================================
# Azure Policy Outputs
# ============================================================================

output "policy_hipaa_initiative_assignment_id" {
  description = "ID of the HIPAA compliance initiative assignment."
  value       = module.policy.hipaa_initiative_assignment_id
}

output "policy_definitions" {
  description = "Map of custom policy definition IDs."
  value       = module.policy.policy_definitions
}

output "policy_assignments" {
  description = "Map of policy assignment IDs."
  value       = module.policy.policy_assignments
}

# ============================================================================
# Security Monitoring Alerts Outputs
# ============================================================================

output "security_alerts_action_group_id" {
  description = "ID of the security alerts action group."
  value       = module.security_alerts.action_group_id
}

output "security_alerts_action_group_name" {
  description = "Name of the security alerts action group."
  value       = module.security_alerts.action_group_name
}

output "security_alerts_rule_ids" {
  description = "Map of security alert rule names to their IDs."
  value       = module.security_alerts.alert_rule_ids
}

# ============================================================================
# Azure Sentinel Outputs
# ============================================================================

output "sentinel_workspace_id" {
  description = "ID of the Sentinel-enabled Log Analytics workspace."
  value       = module.sentinel.sentinel_workspace_id
}

output "sentinel_data_connector_ids" {
  description = "Map of Sentinel data connector names to their IDs."
  value       = module.sentinel.data_connector_ids
}

output "sentinel_analytics_rule_ids" {
  description = "Map of Sentinel analytics rule names to their IDs."
  value       = module.sentinel.analytics_rule_ids
}

# ============================================================================
# RBAC Module Outputs
# ============================================================================

output "rbac_app_service_key_vault_assignment_id" {
  description = "ID of the App Service → Key Vault role assignment."
  value       = module.rbac.app_service_key_vault_assignment_id
}

output "rbac_vm_key_vault_assignment_id" {
  description = "ID of the Bastion VM → Key Vault role assignment."
  value       = module.rbac.vm_key_vault_assignment_id
}

output "rbac_vm_storage_assignment_id" {
  description = "ID of the Bastion VM → Storage Account role assignment."
  value       = module.rbac.vm_storage_assignment_id
}

output "rbac_vm_cosmos_assignment_id" {
  description = "ID of the Bastion VM → Cosmos DB role assignment."
  value       = module.rbac.vm_cosmos_assignment_id
}

output "rbac_admin_user_assignment_ids" {
  description = "Map of admin user principal IDs to their role assignment IDs."
  value       = module.rbac.admin_user_key_vault_assignment_ids
}
