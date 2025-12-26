output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "private_endpoint_id" {
  description = "ID of the storage private endpoint."
  value       = azurerm_private_endpoint.storage.id
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone for storage."
  value       = azurerm_private_dns_zone.storage.id
}

output "container_ids" {
  description = "Map of container names to their resource IDs."
  value       = { for k, v in azurerm_storage_container.this : k => v.id }
}
