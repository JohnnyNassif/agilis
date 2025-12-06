variable "subscription_id" {
  description = "Azure subscription ID for dev bootstrap resources."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID for dev."
  type        = string
}

variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for dev bootstrap resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Naming prefix for dev bootstrap resources."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Optional additional tags."
  type        = map(string)
  default     = {}
}

variable "storage_account_replication_type" {
  description = "Storage replication type for dev state account."
  type        = string
  default     = "ZRS"
}

variable "storage_account_public_network_access_enabled" {
  description = "Allow public network access for the dev state storage account."
  type        = bool
  default     = true
}
