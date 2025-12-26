output "bastion_vm_password" {
  description = "Auto-generated password for Windows jump VM (if password was auto-generated)."
  value       = module.agilis_dev.bastion_vm_password
  sensitive   = true
}

output "bastion_vm_name" {
  description = "Name of the Windows jump VM (if Bastion is enabled)."
  value       = module.agilis_dev.bastion_vm_name
}

output "bastion_vm_admin_username" {
  description = "Administrator username for the Windows jump VM (if Bastion is enabled)."
  value       = module.agilis_dev.bastion_vm_admin_username
}

output "bastion_name" {
  description = "Name of the Azure Bastion host (if Bastion is enabled)."
  value       = module.agilis_dev.bastion_name
}

output "resource_group_name" {
  description = "Name of the primary resource group for this environment."
  value       = module.agilis_dev.resource_group_name
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.agilis_dev.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.agilis_dev.key_vault_uri
}

output "frontdoor_endpoint_hostname" {
  description = "Front Door endpoint hostname (use this to access your application - Front Door is mandatory for HIPAA compliance)."
  value       = try(module.agilis_dev.frontdoor_endpoint_hostname, null)
}

output "frontdoor_profile_name" {
  description = "Name of the Front Door profile (Front Door is mandatory for HIPAA compliance)."
  value       = try(module.agilis_dev.frontdoor_profile_name, null)
}

output "frontdoor_waf_policy_name" {
  description = "Name of the WAF policy (Front Door is mandatory for HIPAA compliance)."
  value       = try(module.agilis_dev.frontdoor_waf_policy_name, null)
}

output "app_service_name" {
  description = "Name of the App Service."
  value       = try(module.agilis_dev.app_service_name, null)
}

output "storage_account_name" {
  description = "Storage account name."
  value       = try(module.agilis_dev.storage_account_name, null)
}

output "cosmos_account_name" {
  description = "Cosmos DB account name."
  value       = try(module.agilis_dev.cosmos_account_name, null)
}

