output "bastion_id" {
  description = "ID of the Azure Bastion host."
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host."
  value       = azurerm_bastion_host.this.name
}

output "vm_id" {
  description = "ID of the Windows jump VM."
  value       = azurerm_windows_virtual_machine.jump.id
}

output "vm_name" {
  description = "Name of the Windows jump VM."
  value       = azurerm_windows_virtual_machine.jump.name
}

output "vm_private_ip" {
  description = "Private IP address of the Windows VM."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_admin_username" {
  description = "Administrator username for the Windows VM."
  value       = var.vm_admin_username
}

