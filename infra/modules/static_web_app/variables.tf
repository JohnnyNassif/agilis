variable "name_prefix" {
  description = "Prefix for naming Static Web App resources (e.g., 'agilisdev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Static Web App is created."
  type        = string
}

variable "location" {
  description = "Azure region for Static Web App (must be a supported region)."
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be 'Free' or 'Standard'."
  }
}

variable "sku_size" {
  description = "SKU size for Static Web App (Free or Standard)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_size)
    error_message = "SKU size must be 'Free' or 'Standard'."
  }
}

variable "app_settings" {
  description = "App settings (environment variables) for Static Web App."
  type        = map(string)
  default     = {}
}

variable "custom_domain_name" {
  description = "Custom domain name for Static Web App (optional, e.g., app.example.com)."
  type        = string
  default     = null
}

variable "custom_domain_validation_type" {
  description = "Validation type for custom domain (cname-delegation or dns-txt-token)."
  type        = string
  default     = "cname-delegation"
  validation {
    condition     = contains(["cname-delegation", "dns-txt-token"], var.custom_domain_validation_type)
    error_message = "Custom domain validation type must be 'cname-delegation' or 'dns-txt-token'."
  }
}

variable "tags" {
  description = "Tags applied to Static Web App resources."
  type        = map(string)
  default     = {}
}

