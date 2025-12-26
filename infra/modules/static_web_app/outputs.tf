output "static_web_app_id" {
  description = "ID of the Static Web App."
  value       = azurerm_static_web_app.this.id
}

output "static_web_app_name" {
  description = "Name of the Static Web App."
  value       = azurerm_static_web_app.this.name
}

output "static_web_app_default_hostname" {
  description = "Default hostname of the Static Web App (e.g., swa-agilis-dev.azurestaticapps.net)."
  value       = azurerm_static_web_app.this.default_host_name
}

output "static_web_app_api_key" {
  description = "API key for deploying to Static Web App (sensitive)."
  value       = azurerm_static_web_app.this.api_key
  sensitive   = true
}

output "static_web_app_principal_id" {
  description = "Principal ID of the Static Web App's managed identity (only available in Standard tier)."
  value       = var.sku_tier == "Standard" && length(azurerm_static_web_app.this.identity) > 0 ? azurerm_static_web_app.this.identity[0].principal_id : null
}

output "static_web_app_tenant_id" {
  description = "Tenant ID of the Static Web App's managed identity (only available in Standard tier)."
  value       = var.sku_tier == "Standard" && length(azurerm_static_web_app.this.identity) > 0 ? azurerm_static_web_app.this.identity[0].tenant_id : null
}

