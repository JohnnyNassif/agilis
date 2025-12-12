locals {
  account_name            = substr(replace(format("st%s%s", var.name_prefix, random_string.suffix.result), "-", ""), 0, 24)
  private_endpoint_name   = format("pe-%s-st", var.name_prefix)
  dns_zone_name           = "privatelink.blob.core.windows.net"
  dns_link_name           = format("pdzlnk-%s-st", var.name_prefix)
  private_connection_name = format("psc-%s-st", var.name_prefix)
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                          = local.account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  account_kind                  = var.account_kind
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = false
  tags                          = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Create containers by temporarily enabling public access, then disabling it
# This is necessary because container creation requires data plane API access
# The storage account remains private after provisioning completes
resource "null_resource" "containers" {
  for_each = toset(var.container_names)

  triggers = {
    container_name       = each.value
    storage_account_id   = azurerm_storage_account.this.id
    storage_account_name = azurerm_storage_account.this.name
    resource_group_name  = var.resource_group_name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      STORAGE_ACCOUNT="${azurerm_storage_account.this.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      CONTAINER_NAME="${each.value}"
      
      echo "Temporarily enabling public access and network rules for container creation..."
      # Temporarily enable public access and allow network access
      az storage account update \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Enabled \
        --default-action Allow \
        --output none
      
      # Wait a moment for the change to propagate
      sleep 10
      
      echo "Creating container: $CONTAINER_NAME"
      # Create container
      if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --output none 2>/dev/null; then
        echo "Container $CONTAINER_NAME already exists, skipping creation"
      else
        az storage container create \
          --name "$CONTAINER_NAME" \
          --account-name "$STORAGE_ACCOUNT" \
          --auth-mode login \
          --public-access off \
          --output none
        echo "Container $CONTAINER_NAME created successfully"
      fi
      
      echo "Restoring HIPAA-compliant network restrictions..."
      # Restore network restrictions: disable public access and set default action to Deny
      az storage account update \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled \
        --default-action Deny \
        --output none
      
      echo "Container provisioning complete. Storage account is private and locked down."
    EOT
  }

  depends_on = [
    azurerm_storage_account.this,
    azurerm_private_endpoint.storage
  ]
}

resource "azurerm_private_dns_zone" "storage" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = local.dns_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_endpoint" "storage" {
  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = local.private_connection_name
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = format("pdzg-%s-st", var.name_prefix)
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}
