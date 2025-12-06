output "resource_group_name" {
  description = "Name of the resource group containing Terraform state artifacts."
  value       = module.state_backend.resource_group_name
}

output "storage_account_name" {
  description = "Name of the storage account holding Terraform state."
  value       = module.state_backend.storage_account_name
}

output "storage_container_name" {
  description = "Name of the state container."
  value       = module.state_backend.container_name
}
