output "resource_group_name" {
  description = "Resource group hosting the Terraform state storage for prod."
  value       = module.bootstrap_prod.resource_group_name
}

output "storage_account_name" {
  description = "Storage account holding Terraform state for prod."
  value       = module.bootstrap_prod.storage_account_name
}

output "storage_container_name" {
  description = "Container name for Terraform state in prod."
  value       = module.bootstrap_prod.storage_container_name
}
