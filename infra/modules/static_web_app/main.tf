locals {
  static_web_app_name = format("swa-%s", var.name_prefix)
}

# Azure Static Web App
resource "azurerm_static_web_app" "this" {
  name                = local.static_web_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = var.sku_tier # Free or Standard
  sku_size            = var.sku_size # Free or Standard

  # Identity (for accessing other Azure resources) - Only available in Standard tier
  dynamic "identity" {
    for_each = var.sku_tier == "Standard" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}

# Custom domain (optional)
resource "azurerm_static_web_app_custom_domain" "this" {
  for_each          = var.custom_domain_name != null ? toset([var.custom_domain_name]) : toset([])
  static_web_app_id = azurerm_static_web_app.this.id
  domain_name       = each.value
  validation_type   = var.custom_domain_validation_type # "cname-delegation" or "dns-txt-token"
}

# App settings (environment variables) - Static Web Apps don't support app_settings in Terraform directly
# Use Azure CLI to set app settings if needed
resource "null_resource" "static_web_app_app_settings" {
  count = length(var.app_settings) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Build setting-names argument
      SETTINGS_ARGS=""
      %{for key, value in var.app_settings~}
      SETTINGS_ARGS="$SETTINGS_ARGS ${key}=${value}"
      %{endfor~}
      
      # Set app settings
      if [ -n "$SETTINGS_ARGS" ]; then
        az staticwebapp appsettings set \
          --name ${azurerm_static_web_app.this.name} \
          --resource-group ${var.resource_group_name} \
          --setting-names $SETTINGS_ARGS || true
      fi
    EOT
  }

  depends_on = [azurerm_static_web_app.this]

  triggers = {
    app_settings   = jsonencode(var.app_settings)
    static_site_id = azurerm_static_web_app.this.id
  }
}

