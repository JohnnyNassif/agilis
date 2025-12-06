variable "subscription_id" {
  description = "Azure subscription ID for bootstrap resources."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "environment" {
  description = "Environment identifier for bootstrap resources (e.g., dev, prod)."
  type        = string
}

variable "location" {
  description = "Azure region for bootstrap resources."
  type        = string
  default     = "eastus"
}

variable "common_prefix" {
  description = "Prefix used when naming bootstrap resources."
  type        = string
  default     = "agilis"
}

variable "tags" {
  description = "Additional tags to set on bootstrap resources."
  type        = map(string)
  default     = {}
}

variable "storage_account_replication_type" {
  description = "Replication strategy for the state storage account."
  type        = string
  default     = "ZRS"
}

variable "storage_account_public_network_access_enabled" {
  description = "Whether public network access is allowed for the state storage account."
  type        = bool
  default     = true
}
