variable "subscription_id" {
  description = "Azure subscription ID for prod bootstrap resources."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID for prod."
  type        = string
}

variable "environment" {
  description = "Environment identifier."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for prod bootstrap resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Naming prefix for prod bootstrap resources."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Optional additional tags."
  type        = map(string)
  default     = {}
}

variable "storage_account_replication_type" {
  description = "Storage replication type for prod state account."
  type        = string
  default     = "ZRS"
}

variable "storage_account_public_network_access_enabled" {
  description = "Allow public network access for the prod state storage account."
  type        = bool
  default     = true
}
