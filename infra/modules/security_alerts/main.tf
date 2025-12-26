locals {
  action_group_name = format("ag-%s-security", var.name_prefix)
}

# Action Group for Security Alerts
# This group receives notifications for all security-related alerts
resource "azurerm_monitor_action_group" "security" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "SecAlert"

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses != null && length(var.alert_email_addresses) > 0 ? var.alert_email_addresses : []
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  dynamic "sms_receiver" {
    for_each = var.alert_sms_numbers != null && length(var.alert_sms_numbers) > 0 ? var.alert_sms_numbers : []
    content {
      name         = "sms-${sms_receiver.key}"
      country_code = var.alert_sms_country_code
      phone_number = sms_receiver.value
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.alert_webhook_urls != null && length(var.alert_webhook_urls) > 0 ? var.alert_webhook_urls : []
    content {
      name        = "webhook-${webhook_receiver.key}"
      service_uri = webhook_receiver.value
    }
  }

  tags = var.tags
}

# Alert Rule: Failed Authentication Attempts (Key Vault)
# Monitors Key Vault audit logs for failed authentication attempts
resource "azurerm_monitor_scheduled_query_rules_alert" "keyvault_failed_auth" {
  count               = var.enable_keyvault_auth_alerts ? 1 : 0
  name                = format("alert-%s-kv-failed-auth", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert when Key Vault authentication failures exceed threshold"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.KEYVAULT"
    | where Category == "AuditEvent"
    | where OperationName == "VaultGet" or OperationName == "VaultPut" or OperationName == "SecretGet"
    | where ResultSignature == "Unauthorized" or ResultSignature == "Forbidden"
    | summarize FailedAttempts = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where FailedAttempts >= ${var.keyvault_failed_auth_threshold}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.keyvault_failed_auth_threshold
  }

  tags = var.tags
}

# Alert Rule: Security Policy Violations
# Monitors Azure Policy compliance state for non-compliant resources
resource "azurerm_monitor_scheduled_query_rules_alert" "policy_violations" {
  count               = var.enable_policy_violation_alerts ? 1 : 0
  name                = format("alert-%s-policy-violations", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert when Azure Policy compliance violations are detected"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    PolicyStates
    | where ResourceGroup == "${var.resource_group_name}"
    | where ComplianceState == "NonCompliant"
    | summarize ViolationCount = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where ViolationCount > 0
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = var.tags
}

# Alert Rule: Front Door WAF Blocked Requests
# Monitors Front Door WAF logs for blocked requests (potential attacks)
# Note: frontdoor_profile_id is always provided from frontdoor_waf module
resource "azurerm_monitor_scheduled_query_rules_alert" "frontdoor_waf_blocked" {
  count               = var.enable_frontdoor_waf_alerts ? 1 : 0
  name                = format("alert-%s-frontdoor-waf-blocked", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert when Front Door WAF blocks requests (potential attacks)"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.CDN"
    | where Category == "FrontDoorWebApplicationFirewallLog"
    | where action_s == "Block"
    | summarize BlockedRequests = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where BlockedRequests >= ${var.frontdoor_waf_blocked_threshold}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.frontdoor_waf_blocked_threshold
  }

  tags = var.tags
}

# Alert Rule: Unusual Storage Account Access Patterns
# Monitors Storage Account access logs for unusual patterns (potential data exfiltration)
# Note: storage_account_id is always provided from storage module
resource "azurerm_monitor_scheduled_query_rules_alert" "storage_unusual_access" {
  count               = var.enable_storage_access_alerts ? 1 : 0
  name                = format("alert-%s-storage-unusual-access", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert on unusual Storage Account access patterns (potential data exfiltration)"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    StorageBlobLogs
    | where TimeGenerated > ago(${var.alert_time_window_minutes}m)
    | where OperationName == "GetBlob" or OperationName == "PutBlob"
    | summarize DataTransferMB = sum(ResponseBodySize + RequestBodySize) / 1048576 by CallerIpAddress, bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where DataTransferMB >= ${var.storage_unusual_access_threshold_mb}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.storage_unusual_access_threshold_mb
  }

  tags = var.tags
}

# Alert Rule: Unusual Cosmos DB Access Patterns
# Monitors Cosmos DB access logs for unusual patterns (potential data exfiltration)
# Note: cosmos_account_id is always provided from cosmos_mongo module
resource "azurerm_monitor_scheduled_query_rules_alert" "cosmos_unusual_access" {
  count               = var.enable_cosmos_access_alerts ? 1 : 0
  name                = format("alert-%s-cosmos-unusual-access", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert on unusual Cosmos DB access patterns (potential data exfiltration)"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DOCUMENTDB"
    | where Category == "DataPlaneRequests"
    | where statusCode_s != "200" or toreal(requestCharge_s) > ${var.cosmos_unusual_ru_threshold}
    | summarize UnusualRequests = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where UnusualRequests >= ${var.cosmos_unusual_access_threshold}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.cosmos_unusual_access_threshold
  }

  tags = var.tags
}

# Alert Rule: NSG Denied Traffic
# Monitors NSG flow logs for denied traffic (potential network attacks)
resource "azurerm_monitor_scheduled_query_rules_alert" "nsg_denied_traffic" {
  count               = var.enable_nsg_alerts && length(var.nsg_ids) > 0 ? 1 : 0
  name                = format("alert-%s-nsg-denied-traffic", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert when NSG denies traffic (potential network attacks)"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    AzureNetworkAnalytics_CL
    | where FlowType_s == "Deny"
    | summarize DeniedPackets = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where DeniedPackets >= ${var.nsg_denied_traffic_threshold}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.nsg_denied_traffic_threshold
  }

  tags = var.tags
}

# Alert Rule: App Service Failed Requests
# Monitors App Service logs for failed requests (potential attacks or issues)
# Note: app_service_id is always provided from app_service module
resource "azurerm_monitor_scheduled_query_rules_alert" "app_service_failed_requests" {
  count               = var.enable_app_service_alerts ? 1 : 0
  name                = format("alert-%s-app-service-failed", var.name_prefix)
  location            = var.location
  resource_group_name = var.resource_group_name

  action {
    action_group = [azurerm_monitor_action_group.security.id]
  }

  data_source_id = var.log_analytics_workspace_id
  description    = "Alert when App Service failed requests exceed threshold"
  enabled        = true
  severity       = var.alert_severity
  frequency      = var.alert_frequency_minutes
  time_window    = var.alert_time_window_minutes

  query = <<-QUERY
    AppServiceHTTPLogs
    | where TimeGenerated > ago(${var.alert_time_window_minutes}m)
    | where ScStatus >= 400
    | summarize FailedRequests = count() by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where FailedRequests >= ${var.app_service_failed_requests_threshold}
  QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = var.app_service_failed_requests_threshold
  }

  tags = var.tags
}

