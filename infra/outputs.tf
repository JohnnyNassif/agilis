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
