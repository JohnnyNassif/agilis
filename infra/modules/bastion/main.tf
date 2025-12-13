locals {
  bastion_name        = format("bas-%s", var.name_prefix)
  bastion_subnet_name = "AzureBastionSubnet"  # Must be exactly this name for Azure Bastion
  vm_subnet_name      = format("snet-%s-vm", var.name_prefix)
  vm_name              = format("vm-%s-jmp", var.name_prefix)  # Shortened to fit Windows 15-char limit
  vm_computer_name     = substr(replace(local.vm_name, "-", ""), 0, 15)  # Remove dashes and limit to 15 chars
  public_ip_name       = format("pip-%s-bastion", var.name_prefix)
}

# Dedicated subnet for Azure Bastion (/27 minimum = 32 IPs)
# IMPORTANT: Must be named exactly "AzureBastionSubnet" (Azure requirement)
# NOTE: Azure Bastion manages NSG rules automatically - do NOT associate a custom NSG
resource "azurerm_subnet" "bastion" {
  name                 = local.bastion_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# Dedicated subnet for Windows VM (cannot use app subnet - it's delegated to App Service)
resource "azurerm_subnet" "vm" {
  name                 = local.vm_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.vm_subnet_cidr]
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion
resource "azurerm_bastion_host" "this" {
  name                = local.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = var.tags
}

# Network interface for Windows VM (no public IP needed - Bastion provides access)
resource "azurerm_network_interface" "vm" {
  name                = format("nic-%s-vm", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Windows VM for jump server
resource "azurerm_windows_virtual_machine" "jump" {
  name                = local.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  computer_name        = local.vm_computer_name  # Explicit computer name (max 15 chars)
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Auto-shutdown schedule for Windows VM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm" {
  virtual_machine_id = azurerm_windows_virtual_machine.jump.id
  location           = var.location
  enabled            = var.auto_shutdown_enabled

  daily_recurrence_time = var.auto_shutdown_time
  timezone              = var.auto_shutdown_timezone

  notification_settings {
    enabled = false  # Disable email notifications (can be enabled if needed)
  }
}

# Grant VM managed identity access to Key Vault
resource "azurerm_role_assignment" "vm_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.jump.identity[0].principal_id
}

