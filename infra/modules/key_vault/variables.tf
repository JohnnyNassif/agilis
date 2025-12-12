variable "name_prefix" {
  description = "Prefix used for naming the Key Vault and resources."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Key Vault resides."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet ID used for the Key Vault private endpoint."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID for DNS linking."
  type        = string
}

variable "app_service_principal_id" {
  description = "Principal ID of the App Service managed identity for Key Vault access."
  type        = string
}

variable "terraform_principal_id" {
  description = "Principal ID of the Terraform service principal for secret management (optional)."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU name for Key Vault (standard or premium)."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault."
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault."
  type        = bool
  default     = true
}

variable "cosmos_connection_string" {
  description = "Cosmos DB connection string to store in Key Vault (optional, can be set later)."
  type        = string
  default     = null
  sensitive   = true
}

variable "cosmos_connection_string_secret_name" {
  description = "Name of the secret in Key Vault for Cosmos connection string."
  type        = string
  default     = "cosmos-connection-string"
}

variable "storage_account_key" {
  description = "Storage account primary key to store in Key Vault (optional, can be set later)."
  type        = string
  default     = null
  sensitive   = true
}

variable "storage_account_key_secret_name" {
  description = "Name of the secret in Key Vault for Storage account key."
  type        = string
  default     = "storage-account-key"
}

variable "storage_account_name" {
  description = "Storage account name to store in Key Vault (for App Service to construct URLs)."
  type        = string
  default     = null
}

variable "storage_account_name_secret_name" {
  description = "Name of the secret in Key Vault for Storage account name."
  type        = string
  default     = "storage-account-name"
}

variable "tags" {
  description = "Tags to apply to Key Vault resources."
  type        = map(string)
}

