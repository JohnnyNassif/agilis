output "account_name" {
  description = "Cosmos DB account name."
  value       = azurerm_cosmosdb_account.this.name
}

output "account_endpoint" {
  description = "Cosmos DB account endpoint."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "Primary key for the Cosmos account (use with caution)."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "private_endpoint_id" {
  description = "ID of the Cosmos DB private endpoint."
  value       = azurerm_private_endpoint.cosmos.id
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone for Cosmos."
  value       = azurerm_private_dns_zone.cosmos.id
}
