locals {
  workspace_name    = format("law-%s", var.name_prefix)
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

# Note: Diagnostic settings are created separately in the root module after all resources exist
# This allows Application Insights and Log Analytics to be created before App Service

