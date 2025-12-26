output "frontdoor_profile_id" {
  description = "ID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "frontdoor_profile_name" {
  description = "Name of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "frontdoor_endpoint_hostname" {
  description = "Hostname of the Front Door endpoint (use this to access your application)."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "frontdoor_endpoint_id" {
  description = "ID of the Front Door endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}

output "waf_policy_id" {
  description = "ID of the WAF policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.id
}

output "waf_policy_name" {
  description = "Name of the WAF policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.name
}

output "custom_domain_id" {
  description = "ID of the custom domain (if configured)."
  value       = var.custom_domain_name != null ? azurerm_cdn_frontdoor_custom_domain.this[0].id : null
}

output "custom_domain_name" {
  description = "Custom domain name (if configured)."
  value       = var.custom_domain_name
}

