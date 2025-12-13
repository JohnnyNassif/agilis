locals {
  workspace_name = format("law-%s", var.name_prefix)
  app_insights_name = format("appi-%s", var.name_prefix)
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "this" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}

# Diagnostic Settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count                      = var.app_service_id != null ? 1 : 0
  name                       = format("diag-%s-app", var.name_prefix)
  target_resource_id          = var.app_service_id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Cosmos DB
resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count                      = var.cosmos_account_id != null ? 1 : 0
  name                       = format("diag-%s-cosmos", var.name_prefix)
  target_resource_id          = var.cosmos_account_id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "PartitionKeyRUConsumption"
  }

  enabled_log {
    category = "ControlPlaneRequests"
  }

  metric {
    category = "Requests"
    enabled  = true
  }

  metric {
    category = "SLI"
    enabled  = true
  }
}

# Diagnostic Settings for Storage Account
# Note: Storage Account log categories are not available for all storage account types
# Only metrics are configured here
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.storage_account_id != null ? 1 : 0
  name                       = format("diag-%s-storage", var.name_prefix)
  target_resource_id          = var.storage_account_id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.id

  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.key_vault_id != null ? 1 : 0
  name                       = format("diag-%s-kv", var.name_prefix)
  target_resource_id          = var.key_vault_id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

