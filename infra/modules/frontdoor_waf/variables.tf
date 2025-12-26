variable "name_prefix" {
  description = "Prefix for naming Front Door resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where Front Door resources are created."
  type        = string
}

variable "sku_name" {
  description = "SKU name for Front Door (Standard_AzureFrontDoor or Premium_AzureFrontDoor)."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "app_service_host_name" {
  description = "Hostname of the App Service backend (e.g., app-agilis-dev-api.azurewebsites.net)."
  type        = string
}

variable "enable_static_web_app_frontend" {
  description = "Enable Static Web App frontend routing. If true, Front Door will route /* to Static Web App and /api/* to App Service."
  type        = bool
  default     = false
}

variable "static_web_app_host_name" {
  description = "Hostname of the Static Web App frontend (e.g., swa-agilis-dev.azurestaticapps.net). Required if enable_static_web_app_frontend is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to Front Door resources."
  type        = map(string)
  default     = {}
}

# WAF Configuration
variable "waf_mode" {
  description = "WAF mode: Detection (log only) or Prevention (block requests)."
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be either 'Detection' or 'Prevention'."
  }
}

variable "waf_redirect_url" {
  description = "URL to redirect blocked requests to (optional)."
  type        = string
  default     = null
}

variable "waf_custom_block_response_status_code" {
  description = "HTTP status code for blocked requests (403 or 405)."
  type        = number
  default     = 403
  validation {
    condition     = contains([403, 405], var.waf_custom_block_response_status_code)
    error_message = "Custom block response status code must be 403 or 405."
  }
}

variable "waf_custom_block_response_body" {
  description = "Custom response body for blocked requests (base64 encoded)."
  type        = string
  default     = null
}

variable "waf_default_rule_set_action" {
  description = "Action for Microsoft Default Rule Set (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
  validation {
    condition     = contains(["Block", "Log", "Redirect"], var.waf_default_rule_set_action)
    error_message = "Default rule set action must be 'Block', 'Log', or 'Redirect'."
  }
}

variable "waf_bot_rule_set_action" {
  description = "Action for Bot Manager Rule Set (Block, Log, or Redirect)."
  type        = string
  default     = "Block"
  validation {
    condition     = contains(["Block", "Log", "Redirect"], var.waf_bot_rule_set_action)
    error_message = "Bot rule set action must be 'Block', 'Log', or 'Redirect'."
  }
}

variable "waf_custom_rules" {
  description = "List of custom WAF rules (optional)."
  type = list(object({
    name                           = string
    enabled                        = bool
    priority                       = number
    rate_limit_duration_in_minutes = number
    rate_limit_threshold           = number
    type                           = string # MatchRule or RateLimitRule
    action                         = string # Allow, Block, Log, or Redirect
    match_variable                 = string
    operator                       = string
    match_values                   = list(string)
    selector                       = string
    negation_condition             = bool
    transforms                     = list(string)
  }))
  default = []
}

# Health Probe Configuration
variable "health_probe_interval" {
  description = "Interval in seconds between health probes."
  type        = number
  default     = 100
}

variable "health_probe_path" {
  description = "Path for health probe requests."
  type        = string
  default     = "/"
}

variable "health_probe_protocol" {
  description = "Protocol for health probes (Http or Https)."
  type        = string
  default     = "Https"
  validation {
    condition     = contains(["Http", "Https"], var.health_probe_protocol)
    error_message = "Health probe protocol must be 'Http' or 'Https'."
  }
}

variable "health_probe_request_type" {
  description = "Request type for health probes (GET or HEAD)."
  type        = string
  default     = "HEAD"
  validation {
    condition     = contains(["GET", "HEAD"], var.health_probe_request_type)
    error_message = "Health probe request type must be 'GET' or 'HEAD'."
  }
}

# Load Balancing Configuration
variable "load_balancing_additional_latency_in_milliseconds" {
  description = "Additional latency in milliseconds for load balancing."
  type        = number
  default     = 50
}

variable "load_balancing_sample_size" {
  description = "Sample size for load balancing."
  type        = number
  default     = 4
}

variable "load_balancing_successful_samples_required" {
  description = "Number of successful samples required for load balancing."
  type        = number
  default     = 3
}

# Routing Configuration
variable "forwarding_protocol" {
  description = "Protocol to use when forwarding requests (HttpOnly, HttpsOnly, or MatchRequest)."
  type        = string
  default     = "HttpsOnly"
  validation {
    condition     = contains(["HttpOnly", "HttpsOnly", "MatchRequest"], var.forwarding_protocol)
    error_message = "Forwarding protocol must be 'HttpOnly', 'HttpsOnly', or 'MatchRequest'."
  }
}

variable "https_redirect_enabled" {
  description = "Enable HTTPS redirect for HTTP requests."
  type        = bool
  default     = true
}

variable "route_patterns_to_match" {
  description = "URL patterns to match for this route."
  type        = list(string)
  default     = ["/*"]
}

variable "supported_protocols" {
  description = "Supported protocols for the route."
  type        = list(string)
  default     = ["Http", "Https"]
}

variable "waf_security_policy_patterns_to_match" {
  description = "URL patterns to match for WAF security policy."
  type        = list(string)
  default     = ["/*"]
}

# Custom Domain Configuration (optional)
variable "custom_domain_name" {
  description = "Custom domain name for Front Door (optional, e.g., api.example.com)."
  type        = string
  default     = null
}

variable "custom_domain_certificate_type" {
  description = "Certificate type for custom domain (Dedicated or ManagedCertificate)."
  type        = string
  default     = "ManagedCertificate"
  validation {
    condition     = contains(["Dedicated", "ManagedCertificate"], var.custom_domain_certificate_type)
    error_message = "Custom domain certificate type must be 'Dedicated' or 'ManagedCertificate'."
  }
}

variable "custom_domain_minimum_tls_version" {
  description = "Minimum TLS version for custom domain (TLS10, TLS12)."
  type        = string
  default     = "TLS12"
  validation {
    condition     = contains(["TLS10", "TLS12"], var.custom_domain_minimum_tls_version)
    error_message = "Custom domain minimum TLS version must be 'TLS10' or 'TLS12'."
  }
}

