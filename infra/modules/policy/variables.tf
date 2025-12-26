variable "name_prefix" {
  description = "Prefix for naming policy definitions (to ensure uniqueness across environments)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where policies will be assigned."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID where policies will be assigned."
  type        = string
}

variable "management_group_id" {
  description = "Optional management group ID for policy assignment (if not provided, assigns to subscription)."
  type        = string
  default     = null
}

variable "enable_hipaa_initiative" {
  description = "Enable HIPAA compliance policy initiative assignment."
  type        = bool
  default     = true
}

variable "enable_custom_policies" {
  description = "Enable custom HIPAA-specific policy assignments."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings policies."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to policy resources."
  type        = map(string)
  default     = {}
}

