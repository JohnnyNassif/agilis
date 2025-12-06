variable "name_prefix" {
  description = "Prefix for naming the App Service plan and app."
  type        = string
}

variable "location" {
  description = "Azure region for the App Service resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the App Service resources are created."
  type        = string
}

variable "app_service_sku_name" {
  description = "App Service plan SKU name (e.g., P1v3, S2)."
  type        = string
  default     = "P1v3"
}

variable "app_service_plan_capacity" {
  description = "Optional number of workers for the plan."
  type        = number
  default     = 1
}

variable "app_settings" {
  description = "Map of App Service application settings."
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "List of connection strings to configure for the app."
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "subnet_id" {
  description = "Subnet ID used for VNet integration."
  type        = string
}

variable "node_version" {
  description = "Node.js runtime version to use."
  type        = string
  default     = "18-lts"
}

variable "tags" {
  description = "Tags applied to the App Service resources."
  type        = map(string)
}
