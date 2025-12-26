locals {
  plan_name = format("asp-%s-web%s", var.name_prefix, var.name_suffix)
  app_name  = format("app-%s-api%s", var.name_prefix, var.name_suffix)
}

resource "azurerm_service_plan" "this" {
  name                = local.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name
  worker_count        = var.app_service_plan_capacity
  tags                = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_linux_web_app" "this" {
  name                = local.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  site_config {
    ftps_state          = "Disabled"
    always_on           = var.always_on
    http2_enabled       = true
    minimum_tls_version = "1.2"
    application_stack {
      node_version = var.node_version
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge({
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITE_RUN_FROM_PACKAGE            = "0"
  }, var.app_settings)

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  tags = var.tags

  lifecycle {
    # The VNet integration is managed via `azurerm_app_service_virtual_network_swift_connection`.
    # AzureRM may reflect this integration on the web app resource as `virtual_network_subnet_id`,
    # even though we don't set it here. Ignore that computed drift to avoid Terraform trying to
    # "unset" VNet integration during unrelated changes.
    ignore_changes = [virtual_network_subnet_id]
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "integration" {
  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = var.subnet_id
}
