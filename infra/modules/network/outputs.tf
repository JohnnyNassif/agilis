output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "app_subnet_id" {
  description = "ID of the application subnet for App Service integration."
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  description = "ID of the data subnet for private endpoints."
  value       = azurerm_subnet.data.id
}
