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

