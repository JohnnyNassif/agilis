locals {
  sentinel_name = format("sentinel-%s", var.name_prefix)
}

# Onboard Azure Sentinel to Log Analytics Workspace
# Sentinel is enabled on the Log Analytics Workspace itself
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  workspace_id                 = var.log_analytics_workspace_id
  customer_managed_key_enabled = var.enable_customer_managed_key
}

# Data Connector: Azure Activity Log
# NOTE: Azure Activity Log connector is often managed by Microsoft Threat Protection Portal
# If the workspace is enabled through Threat Protection Portal, this connector cannot be managed via Terraform
# Set enable_azure_activity_connector = false if you get "Changes to the connector in Microsoft Sentinel are disabled" error
# The connector can be managed manually in the Azure Portal if needed
resource "azurerm_sentinel_data_connector_azure_active_directory" "activity_log" {
  count                      = var.enable_azure_activity_connector ? 1 : 0
  name                       = format("dc-%s-azure-activity", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tenant_id                  = var.tenant_id

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Data Connector: Azure Security Center
# Collects security alerts and recommendations from Azure Security Center
resource "azurerm_sentinel_data_connector_azure_security_center" "security_center" {
  count                      = var.enable_security_center_connector ? 1 : 0
  name                       = format("dc-%s-security-center", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  subscription_id            = var.subscription_id

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# NOTE: Key Vault and Storage Account logs are collected via diagnostic settings (configured in root main.tf)
# These services don't have dedicated Sentinel data connectors in Terraform.
# The logs are already flowing to Log Analytics via AzureDiagnostics and StorageBlobLogs tables.
# Sentinel analytics rules can query these tables directly without separate data connectors.

# Analytics Rule: Failed Key Vault Authentication Attempts
# Detects multiple failed authentication attempts to Key Vault
resource "azurerm_sentinel_alert_rule_scheduled" "keyvault_failed_auth" {
  count                      = var.enable_keyvault_failed_auth_rule ? 1 : 0
  name                       = format("ar-%s-kv-failed-auth", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: Multiple Failed Key Vault Authentication Attempts"
  description                = "Detects multiple failed authentication attempts to Key Vault, which may indicate a brute force attack"
  severity                   = "High"
  enabled                    = true
  query                      = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.KEYVAULT"
    | where Category == "AuditEvent"
    | where OperationName in ("VaultGet", "VaultPut", "SecretGet", "SecretSet")
    | where ResultSignature in ("Unauthorized", "Forbidden")
    | summarize FailedAttempts = count(), FailedIPs = make_set(CallerIPAddress), FailedOperations = make_set(OperationName) by CallerIPAddress, bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where FailedAttempts >= ${var.keyvault_failed_auth_threshold}
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = var.keyvault_failed_auth_threshold

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Analytics Rule: Policy Compliance Violations
# Detects Azure Policy compliance violations
# NOTE: This rule requires Azure Policy Insights connector to be enabled in Sentinel
# The PolicyStates table is only populated when Policy Insights connector is enabled
# Enable it manually in Azure Portal: Sentinel > Data Connectors > Azure Policy
resource "azurerm_sentinel_alert_rule_scheduled" "policy_violations" {
  count                      = var.enable_policy_violation_rule ? 1 : 0
  name                       = format("ar-%s-policy-violations", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: Azure Policy Compliance Violations"
  description                = "Detects Azure Policy compliance violations that may impact HIPAA compliance. NOTE: Requires Azure Policy Insights connector to be enabled."
  severity                   = "Medium"
  enabled                    = false # Disabled by default - enable manually after Policy Insights connector is enabled
  query                      = <<-QUERY
    PolicyStates
    | where ResourceGroup == "${var.resource_group_name}"
    | where ComplianceState == "NonCompliant"
    | summarize ViolationCount = count(), ViolatedResources = make_set(ResourceId), ViolatedPolicies = make_set(PolicyDefinitionName) by PolicyAssignmentName, bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where ViolationCount > 0
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = 0

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Analytics Rule: Unusual Storage Account Access Patterns
# Detects potential data exfiltration attempts
resource "azurerm_sentinel_alert_rule_scheduled" "storage_unusual_access" {
  count                      = var.enable_storage_unusual_access_rule ? 1 : 0
  name                       = format("ar-%s-storage-unusual-access", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: Unusual Storage Account Access Patterns"
  description                = "Detects unusual data transfer patterns from Storage Account, which may indicate data exfiltration"
  severity                   = "High"
  enabled                    = true
  query                      = <<-QUERY
    StorageBlobLogs
    | where TimeGenerated > ago(${var.alert_time_window_minutes}m)
    | where OperationName in ("GetBlob", "PutBlob")
    | summarize DataTransferMB = sum(ResponseBodySize + RequestBodySize) / 1048576, OperationCount = count(), Operations = make_set(OperationName) by CallerIpAddress, bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where DataTransferMB >= ${var.storage_unusual_access_threshold_mb}
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = var.storage_unusual_access_threshold_mb

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Analytics Rule: Unusual Cosmos DB Access Patterns
# Detects potential data exfiltration attempts
resource "azurerm_sentinel_alert_rule_scheduled" "cosmos_unusual_access" {
  count                      = var.enable_cosmos_unusual_access_rule ? 1 : 0
  name                       = format("ar-%s-cosmos-unusual-access", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: Unusual Cosmos DB Access Patterns"
  description                = "Detects unusual access patterns to Cosmos DB, which may indicate data exfiltration or unauthorized access"
  severity                   = "High"
  enabled                    = true
  query                      = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.DOCUMENTDB"
    | where Category == "DataPlaneRequests"
    | extend StatusCode = coalesce(tostring(statusCode_s), "200"), 
             RequestCharge = coalesce(toreal(requestCharge_s), 0.0)
    | where StatusCode != "200" or RequestCharge > ${var.cosmos_unusual_ru_threshold}
    | summarize UnusualRequests = count(), FailedRequests = countif(StatusCode != "200"), HighRURequests = countif(RequestCharge > ${var.cosmos_unusual_ru_threshold}), StatusCodes = make_set(StatusCode) by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where UnusualRequests >= ${var.cosmos_unusual_access_threshold}
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = var.cosmos_unusual_access_threshold

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Analytics Rule: Front Door WAF Blocked Requests
# Detects potential attacks blocked by WAF
# NOTE: This rule requires Front Door diagnostic settings to be configured to send WAF logs to Log Analytics
# Front Door WAF logs are now configured via diagnostic settings (P0.4)
# Logs appear in AzureDiagnostics table with Category == "FrontDoorWebApplicationFirewallLog"
# The rule is disabled by default - enable it after verifying logs are flowing (wait 15-30 minutes after diagnostic settings are created)
resource "azurerm_sentinel_alert_rule_scheduled" "frontdoor_waf_blocked" {
  count                      = var.enable_frontdoor_waf_rule ? 1 : 0
  name                       = format("ar-%s-frontdoor-waf-blocked", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: Front Door WAF Blocked Requests"
  description                = "Detects multiple requests blocked by Front Door WAF, which may indicate an attack. P0.4: Front Door diagnostic settings are configured to send WAF logs to Log Analytics."
  severity                   = "Medium"
  enabled                    = false # Disabled by default - enable manually after verifying logs are flowing (wait 15-30 minutes)
  query                      = <<-QUERY
    AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.CDN"
    | where Category == "FrontDoorWebApplicationFirewallLog"
    | where Properties has "Block" or tostring(Properties.action) == "Block" or tostring(Properties.action_s) == "Block"
    | extend ClientIP = coalesce(tostring(Properties.clientIp_s), tostring(Properties.clientIp), ""), RuleName = coalesce(tostring(Properties.ruleName_s), tostring(Properties.ruleName), ""), RequestUri = coalesce(tostring(Properties.requestUri_s), tostring(Properties.requestUri), "")
    | summarize BlockedRequests = count(), BlockedIPs = make_set(ClientIP), BlockedRules = make_set(RuleName), BlockedURIs = make_set(RequestUri) by ClientIP, bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where BlockedRequests >= ${var.frontdoor_waf_blocked_threshold}
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = var.frontdoor_waf_blocked_threshold

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

# Analytics Rule: App Service Failed Requests
# Detects potential attacks or issues with App Service
resource "azurerm_sentinel_alert_rule_scheduled" "app_service_failed_requests" {
  count                      = var.enable_app_service_failed_requests_rule ? 1 : 0
  name                       = format("ar-%s-app-service-failed", var.name_prefix)
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "HIPAA: App Service Failed Requests"
  description                = "Detects high number of failed requests to App Service, which may indicate an attack or application issue"
  severity                   = "Medium"
  enabled                    = true
  query                      = <<-QUERY
    AppServiceHTTPLogs
    | where TimeGenerated > ago(${var.alert_time_window_minutes}m)
    | where ScStatus >= 400
    | summarize FailedRequests = count(), FailedStatusCodes = make_set(ScStatus), FailedURIs = make_set(CsUriStem), FailedIPs = make_set(CsHost) by bin(TimeGenerated, ${var.alert_time_window_minutes}m)
    | where FailedRequests >= ${var.app_service_failed_requests_threshold}
  QUERY

  query_frequency   = "PT${var.alert_frequency_minutes}M"
  query_period      = "PT${var.alert_time_window_minutes}M"
  trigger_operator  = "GreaterThan"
  trigger_threshold = var.app_service_failed_requests_threshold

  dynamic "event_grouping" {
    for_each = var.enable_event_grouping ? [1] : []
    content {
      aggregation_method = "AlertPerResult"
    }
  }

  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.this
  ]
}

