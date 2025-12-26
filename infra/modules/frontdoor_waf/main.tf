locals {
  frontdoor_name = format("fd-%s", var.name_prefix)
  # WAF policy name must start with letter and contain only letters/numbers (no hyphens)
  waf_policy_name               = replace(format("waf%s", var.name_prefix), "-", "")
  frontend_endpoint_name        = format("fe-%s", var.name_prefix)
  backend_pool_name             = format("be-%s-backend", var.name_prefix)
  frontend_pool_name            = format("be-%s-frontend", var.name_prefix)
  backend_route_name            = format("rr-%s-backend", var.name_prefix)
  backend_whiteboard_route_name = format("rr-%s-backend-whiteboard", var.name_prefix)
  backend_telehealth_route_name = format("rr-%s-backend-telehealth", var.name_prefix)
  frontend_route_name           = format("rr-%s-frontend", var.name_prefix)
  health_probe_name             = format("hp-%s", var.name_prefix)
}

# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.frontdoor_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name # Standard_AzureFrontDoor or Premium_AzureFrontDoor
  tags                = var.tags
}

# WAF Policy with OWASP Top 10 rules
# NOTE: Managed rule sets (OWASP Top 10) are only available with Premium_AzureFrontDoor SKU
# Standard_AzureFrontDoor SKU supports custom rules only
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                              = local.waf_policy_name
  resource_group_name               = var.resource_group_name
  sku_name                          = var.sku_name
  enabled                           = true
  mode                              = var.waf_mode # Detection or Prevention
  redirect_url                      = var.waf_redirect_url
  custom_block_response_status_code = var.waf_custom_block_response_status_code
  custom_block_response_body        = var.waf_custom_block_response_body

  # Managed rule sets (OWASP Top 10) - Only available with Premium SKU
  # For Standard SKU, only custom rules are supported
  dynamic "managed_rule" {
    for_each = var.sku_name == "Premium_AzureFrontDoor" ? [1] : []
    content {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      action  = var.waf_default_rule_set_action # Block, Log, or Redirect
    }
  }

  dynamic "managed_rule" {
    for_each = var.sku_name == "Premium_AzureFrontDoor" ? [1] : []
    content {
      type    = "Microsoft_BotManagerRuleSet"
      version = "1.0"
      action  = var.waf_bot_rule_set_action # Block, Log, or Redirect
    }
  }

  # Custom rules (optional)
  dynamic "custom_rule" {
    for_each = var.waf_custom_rules
    content {
      name                           = custom_rule.value.name
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold
      type                           = custom_rule.value.type   # MatchRule or RateLimitRule
      action                         = custom_rule.value.action # Allow, Block, Log, or Redirect

      match_condition {
        match_variable     = custom_rule.value.match_variable
        operator           = custom_rule.value.operator
        match_values       = custom_rule.value.match_values
        selector           = custom_rule.value.selector
        negation_condition = custom_rule.value.negation_condition
        transforms         = custom_rule.value.transforms
      }
    }
  }

  tags = var.tags
}

# Frontend Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.frontend_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.tags
}

# Custom Domain (optional - if provided)
resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  count                    = var.custom_domain_name != null ? 1 : 0
  name                     = replace(var.custom_domain_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name                = var.custom_domain_name

  # TLS/SSL configuration
  tls {
    certificate_type    = var.custom_domain_certificate_type # Dedicated or ManagedCertificate
    minimum_tls_version = var.custom_domain_minimum_tls_version
  }
}

# Backend Origin Group (App Service)
resource "azurerm_cdn_frontdoor_origin_group" "backend" {
  name                     = local.backend_pool_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  health_probe {
    interval_in_seconds = var.health_probe_interval
    path                = var.health_probe_path
    protocol            = var.health_probe_protocol     # Http or Https
    request_type        = var.health_probe_request_type # GET or HEAD
  }

  load_balancing {
    additional_latency_in_milliseconds = var.load_balancing_additional_latency_in_milliseconds
    sample_size                        = var.load_balancing_sample_size
    successful_samples_required        = var.load_balancing_successful_samples_required
  }
}

# Backend Origin (App Service)
resource "azurerm_cdn_frontdoor_origin" "app_service" {
  name                          = format("origin-%s-app", var.name_prefix)
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  enabled                       = true
  host_name                     = var.app_service_host_name
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = var.app_service_host_name
  priority                      = 1
  weight                        = 1000

  certificate_name_check_enabled = true
}

# Optional Backend Origin (Whiteboard App Service)
resource "azurerm_cdn_frontdoor_origin" "app_service_whiteboard" {
  count                         = var.whiteboard_app_service_host_name != null ? 1 : 0
  name                          = format("origin-%s-app-whiteboard", var.name_prefix)
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  enabled                       = true
  host_name                     = var.whiteboard_app_service_host_name
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = var.whiteboard_app_service_host_name
  priority                      = 1
  weight                        = 1000

  certificate_name_check_enabled = true
}

# Optional Backend Origin (Telehealth App Service)
resource "azurerm_cdn_frontdoor_origin" "app_service_telehealth" {
  count                         = var.telehealth_app_service_host_name != null ? 1 : 0
  name                          = format("origin-%s-app-telehealth", var.name_prefix)
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  enabled                       = true
  host_name                     = var.telehealth_app_service_host_name
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = var.telehealth_app_service_host_name
  priority                      = 1
  weight                        = 1000

  certificate_name_check_enabled = true
}

# Frontend Origin Group (Static Web App) - Only created if Static Web App frontend is enabled
resource "azurerm_cdn_frontdoor_origin_group" "frontend" {
  count                    = var.enable_static_web_app_frontend ? 1 : 0
  name                     = local.frontend_pool_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  # Static Web Apps don't need health probes (they're managed by Azure)
  load_balancing {
    additional_latency_in_milliseconds = var.load_balancing_additional_latency_in_milliseconds
    sample_size                        = var.load_balancing_sample_size
    successful_samples_required        = var.load_balancing_successful_samples_required
  }
}

# Frontend Origin (Static Web App)
resource "azurerm_cdn_frontdoor_origin" "static_web_app" {
  count                         = var.enable_static_web_app_frontend ? 1 : 0
  name                          = format("origin-%s-frontend", var.name_prefix)
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend[0].id
  enabled                       = true
  host_name                     = var.static_web_app_host_name
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = var.static_web_app_host_name
  priority                      = 1
  weight                        = 1000

  certificate_name_check_enabled = true
}

# Backend Routing Rule (/api/* → App Service)
resource "azurerm_cdn_frontdoor_route" "backend" {
  name                          = local.backend_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_service.id]
  cdn_frontdoor_rule_set_ids    = []
  enabled                       = true

  forwarding_protocol    = var.forwarding_protocol # HttpOnly, HttpsOnly, or MatchRequest
  https_redirect_enabled = var.https_redirect_enabled
  patterns_to_match      = ["/api/*"]              # Route API requests to backend
  supported_protocols    = var.supported_protocols # ["Http", "Https"]

  # Link custom domain if provided
  cdn_frontdoor_custom_domain_ids = var.custom_domain_name != null ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []
}

# Optional Backend Routing Rule (/api/whiteboard/* → Whiteboard App Service)
resource "azurerm_cdn_frontdoor_route" "backend_whiteboard" {
  count                         = var.whiteboard_app_service_host_name != null ? 1 : 0
  name                          = local.backend_whiteboard_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_service_whiteboard[0].id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.backend_whiteboard[0].id]
  enabled                       = true

  forwarding_protocol    = var.forwarding_protocol # HttpOnly, HttpsOnly, or MatchRequest
  https_redirect_enabled = var.https_redirect_enabled
  patterns_to_match      = ["/api/whiteboard/*"]
  supported_protocols    = var.supported_protocols # ["Http", "Https"]

  # Link custom domain if provided
  cdn_frontdoor_custom_domain_ids = var.custom_domain_name != null ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []
}

# Optional Backend Routing Rule (/api/telehealth/* → Telehealth App Service)
resource "azurerm_cdn_frontdoor_route" "backend_telehealth" {
  count                         = var.telehealth_app_service_host_name != null ? 1 : 0
  name                          = local.backend_telehealth_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.backend.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_service_telehealth[0].id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.backend_telehealth[0].id]
  enabled                       = true

  forwarding_protocol    = var.forwarding_protocol # HttpOnly, HttpsOnly, or MatchRequest
  https_redirect_enabled = var.https_redirect_enabled
  patterns_to_match      = ["/api/telehealth/*"]
  supported_protocols    = var.supported_protocols # ["Http", "Https"]

  # Link custom domain if provided
  cdn_frontdoor_custom_domain_ids = var.custom_domain_name != null ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []
}

# ============================================================================
# Route-specific rewrite rule sets
# ============================================================================

# Rewrite /api/whiteboard/* -> /api/* before forwarding to the whiteboard origin
resource "azurerm_cdn_frontdoor_rule_set" "backend_whiteboard" {
  count                    = var.whiteboard_app_service_host_name != null ? 1 : 0
  name                     = format("rs%swhiteboardrewrite", replace(var.name_prefix, "-", ""))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "backend_whiteboard_rewrite" {
  count                     = var.whiteboard_app_service_host_name != null ? 1 : 0
  name                      = format("rw%swhiteboard", replace(var.name_prefix, "-", ""))
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.backend_whiteboard[0].id
  order                     = 1

  actions {
    url_rewrite_action {
      source_pattern          = "/api/whiteboard/*"
      destination             = "/api/"
      preserve_unmatched_path = true
    }
  }
}

# Rewrite /api/telehealth/* -> /api/* before forwarding to the telehealth origin
resource "azurerm_cdn_frontdoor_rule_set" "backend_telehealth" {
  count                    = var.telehealth_app_service_host_name != null ? 1 : 0
  name                     = format("rs%stelehealthrewrite", replace(var.name_prefix, "-", ""))
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
}

resource "azurerm_cdn_frontdoor_rule" "backend_telehealth_rewrite" {
  count                     = var.telehealth_app_service_host_name != null ? 1 : 0
  name                      = format("rw%stelehealth", replace(var.name_prefix, "-", ""))
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.backend_telehealth[0].id
  order                     = 1

  actions {
    url_rewrite_action {
      source_pattern          = "/api/telehealth/*"
      destination             = "/api/"
      preserve_unmatched_path = true
    }
  }
}

# Frontend Routing Rule (/* → Static Web App) - Only created if Static Web App frontend is enabled
resource "azurerm_cdn_frontdoor_route" "frontend" {
  count                         = var.enable_static_web_app_frontend ? 1 : 0
  name                          = local.frontend_route_name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_web_app[0].id]
  cdn_frontdoor_rule_set_ids    = []
  enabled                       = true

  forwarding_protocol    = var.forwarding_protocol # HttpOnly, HttpsOnly, or MatchRequest
  https_redirect_enabled = var.https_redirect_enabled
  patterns_to_match      = ["/*"]                  # Route all other requests to frontend
  supported_protocols    = var.supported_protocols # ["Http", "Https"]

  # Link custom domain if provided
  cdn_frontdoor_custom_domain_ids = var.custom_domain_name != null ? [azurerm_cdn_frontdoor_custom_domain.this[0].id] : []
}

# Security Policy (links WAF policy to Front Door endpoint)
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = format("sec-%s", var.name_prefix)
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        patterns_to_match = var.waf_security_policy_patterns_to_match
        domain {
          cdn_frontdoor_domain_id = var.custom_domain_name != null ? azurerm_cdn_frontdoor_custom_domain.this[0].id : azurerm_cdn_frontdoor_endpoint.this.id
        }
      }
    }
  }
}

