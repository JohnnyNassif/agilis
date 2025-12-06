output "resource_group_name" {
  description = "Name of the Terraform state resource group."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Name of the Terraform state storage account."
  value       = azurerm_storage_account.state.name
}

output "storage_account_id" {
  description = "ID of the Terraform state storage account."
  value       = azurerm_storage_account.state.id
}

output "container_name" {
  description = "Terraform state container name."
  value       = azurerm_storage_container.state.name
}
