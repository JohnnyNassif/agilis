output "app_service_key_vault_assignment_id" {
  description = "ID of the App Service → Key Vault role assignment."
  value       = azurerm_role_assignment.app_service_key_vault_secrets_user.id
}

output "vm_key_vault_assignment_id" {
  description = "ID of the Bastion VM → Key Vault role assignment."
  value       = try(azurerm_role_assignment.vm_key_vault_secrets_user[0].id, null)
}

output "vm_storage_assignment_id" {
  description = "ID of the Bastion VM → Storage Account role assignment."
  value       = try(azurerm_role_assignment.vm_storage_blob_data_contributor[0].id, null)
}

output "vm_cosmos_assignment_id" {
  description = "ID of the Bastion VM → Cosmos DB role assignment."
  value       = try(azurerm_role_assignment.vm_cosmos_db_account_reader[0].id, null)
}

# Terraform SPN and Current User Key Vault assignments are now handled by Key Vault module
# Outputs removed - use module.key_vault outputs instead

output "admin_user_key_vault_assignment_ids" {
  description = "Map of admin user principal IDs to their Key Vault role assignment IDs."
  value       = { for k, v in azurerm_role_assignment.admin_users_key_vault_secrets_officer : k => v.id }
}

output "admin_user_resource_group_assignment_ids" {
  description = "Map of admin user principal IDs to their Resource Group Contributor role assignment IDs."
  value       = { for k, v in azurerm_role_assignment.admin_users_resource_group_contributor : k => v.id }
}

output "admin_user_subscription_assignment_ids" {
  description = "Map of admin user principal IDs to their Subscription Reader role assignment IDs."
  value       = { for k, v in azurerm_role_assignment.admin_users_subscription_reader : k => v.id }
}

