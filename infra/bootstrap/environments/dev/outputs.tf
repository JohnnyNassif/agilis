output "resource_group_name" {
  description = "Resource group hosting the Terraform state storage for dev."
  value       = module.bootstrap_dev.resource_group_name
}

output "storage_account_name" {
  description = "Storage account holding Terraform state for dev."
  value       = module.bootstrap_dev.storage_account_name
}

output "storage_container_name" {
  description = "Container name for Terraform state in dev."
  value       = module.bootstrap_dev.storage_container_name
}
