output "app_service_plan_id" {
  description = "ID of the App Service plan."
  value       = azurerm_service_plan.this.id
}

output "app_service_name" {
  description = "Name of the App Service."
  value       = azurerm_linux_web_app.this.name
}

output "app_service_id" {
  description = "ID of the App Service."
  value       = azurerm_linux_web_app.this.id
}

output "principal_id" {
  description = "System-assigned identity principal ID."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "System-assigned identity tenant ID."
  value       = azurerm_linux_web_app.this.identity[0].tenant_id
}
