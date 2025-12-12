output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_id" {
  description = "ID of the Key Vault private endpoint."
  value       = azurerm_private_endpoint.key_vault.id
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone for Key Vault."
  value       = azurerm_private_dns_zone.key_vault.id
}

output "cosmos_connection_string_secret_name" {
  description = "Name of the Cosmos connection string secret."
  value       = var.cosmos_connection_string_secret_name
}

output "storage_account_key_secret_name" {
  description = "Name of the Storage account key secret."
  value       = var.storage_account_key_secret_name
}

output "storage_account_name_secret_name" {
  description = "Name of the Storage account name secret."
  value       = var.storage_account_name_secret_name
}

