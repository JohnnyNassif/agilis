output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "app_subnet_id" {
  description = "ID of the application subnet for App Service integration."
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  description = "ID of the data subnet for private endpoints."
  value       = azurerm_subnet.data.id
}

output "app_nsg_id" {
  description = "ID of the application subnet NSG."
  value       = azurerm_network_security_group.app.id
}

output "data_nsg_id" {
  description = "ID of the data subnet NSG."
  value       = azurerm_network_security_group.data.id
}
