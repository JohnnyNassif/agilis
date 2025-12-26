variable "name_prefix" {
  description = "Prefix for naming RBAC role assignments (e.g., 'agilisdev')."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for subscription-level role assignments."
  type        = string
  default     = null
}

variable "resource_group_id" {
  description = "Resource Group ID for resource group-level role assignments."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID for Key Vault role assignments."
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Storage Account ID for Storage Account role assignments."
  type        = string
  default     = null
}

variable "cosmos_account_id" {
  description = "Cosmos DB Account ID for Cosmos DB role assignments."
  type        = string
  default     = null
}

variable "app_service_principal_id" {
  description = "App Service managed identity principal ID for RBAC assignments."
  type        = string
  default     = null
}

variable "bastion_vm_principal_id" {
  description = "Bastion VM managed identity principal ID for RBAC assignments."
  type        = string
  default     = null
}

variable "bastion_enabled" {
  description = "Whether Bastion VM is enabled. Used to determine if RBAC assignments should be created."
  type        = bool
  default     = false
}

variable "terraform_principal_id" {
  description = "Terraform service principal ID for RBAC assignments (used for infrastructure deployment)."
  type        = string
  default     = null
}

variable "admin_user_principal_ids" {
  description = "List of admin user principal IDs (Object IDs) for client admin access. Supports up to 3 admin users."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.admin_user_principal_ids) <= 3
    error_message = "Maximum 3 admin users are supported."
  }
}

variable "enable_admin_users" {
  description = "Enable RBAC assignments for admin users (client admins). Set to true for production (client account), false for development (personal account)."
  type        = bool
  default     = false
}

variable "enable_current_user_access" {
  description = "Enable RBAC assignment for current user (useful for development/testing in personal Azure accounts). Set to false for production (client account)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to RBAC role assignments (if supported)."
  type        = map(string)
  default     = {}
}

