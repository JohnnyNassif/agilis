variable "name_prefix" {
  description = "Prefix for naming Bastion and VM resources."
  type        = string
}

variable "location" {
  description = "Azure region for Bastion resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Bastion resources are created."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network for Bastion subnet."
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for Bastion subnet (minimum /27 = 32 IPs)."
  type        = string
  default     = "10.10.3.0/27"
}

variable "vm_subnet_cidr" {
  description = "CIDR block for Windows VM subnet (cannot use app subnet - it's delegated to App Service)."
  type        = string
  default     = "10.10.4.0/24"
}

variable "vm_size" {
  description = "Size of the Windows VM (e.g., Standard_B1s)."
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Administrator username for Windows VM."
  type        = string
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Administrator password for Windows VM."
  type        = string
  sensitive   = true
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown schedule for the VM."
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time for auto-shutdown (24-hour format, e.g., '1800' for 6 PM)."
  type        = string
  default     = "1800"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown schedule."
  type        = string
  default     = "UTC"
}

variable "key_vault_id" {
  description = "Key Vault ID for granting VM managed identity access."
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID for granting VM managed identity access (optional)."
  type        = string
  default     = null
}

variable "cosmos_account_id" {
  description = "Cosmos DB Account ID for granting VM managed identity access (optional)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to Bastion resources."
  type        = map(string)
}

