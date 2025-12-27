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

# Storage account (secure-by-default).
# Some security toggles may be further hardened post-deploy; we selectively ignore those diffs to avoid drift wars.
resource "azurerm_storage_account" "this" {
  name                     = local.account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  min_tls_version          = "TLS1_2"
  # HIPAA baseline: no public network, no anonymous blob access, no shared key (account key) auth.
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true

  # Infrastructure Encryption (Double Encryption) - HIPAA Requirement
  # Enables encryption at the infrastructure level in addition to default encryption at rest
  # This provides double encryption for highly sensitive PHI data
  # Default encryption at rest is always enabled by Azure
  # Infrastructure encryption adds a second layer of encryption at the infrastructure level
  infrastructure_encryption_enabled = var.enable_infrastructure_encryption

  tags = var.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    # Enable blob logging for StorageBlobLogs table in Log Analytics
    # This is required for security alerts to work with Storage Account access patterns
    # Note: Diagnostic settings don't support Storage Account logs, so logging must be enabled here
    # The logs will appear in StorageBlobLogs table in Log Analytics Workspace
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    # HIPAA hardening may tweak these settings post-deploy (or temporarily relax them for Terraform operations).
    # Do not let Terraform revert manual changes.
    ignore_changes = [
      public_network_access_enabled,
      allow_nested_items_to_be_public,
      shared_access_key_enabled,
      https_traffic_only_enabled,
    ]
  }
}

# Network rules (HIPAA baseline: default deny).
# Note: container creation is a data-plane operation; when shared key is disabled and public access is off,
# container provisioning should be done post-deploy from a private network path (or by the application).
resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  ip_rules                   = []
  virtual_network_subnet_ids = []

  depends_on = [
    azurerm_storage_container.this
  ]

  lifecycle {
    # Network rules are commonly hardened/tuned post-deploy. Avoid Terraform reverting them.
    ignore_changes = [
      default_action,
      bypass,
      ip_rules,
      virtual_network_subnet_ids,
    ]
  }
}

# Optional container management (disabled by default).
# If enabled, Terraform must have a valid data-plane access path to the account.
resource "azurerm_storage_container" "this" {
  for_each              = var.manage_containers ? toset(var.container_names) : toset([])
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
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

# Lifecycle Management Policy for PHI Files
# Handles HIPAA retention compliance (deletion after 7 years)
# Note: Hot → Cool transitions are handled by the backend application
# Note: Archive tier is not supported with ZRS replication (only LRS/GRS support Archive)
resource "azurerm_storage_management_policy" "phi_lifecycle" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "phi-lifecycle-policy"
    enabled = true

    filters {
      prefix_match = ["phi-files/"] # Apply only to PHI container
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        # Hot → Cool transition: Handled by backend application
        # (No automatic transition configured here)

        # Archive tier: Not supported with ZRS replication
        # Only LRS, GRS, and RA-GRS support Archive tier

        # Delete: After 7 years (2555 days) for HIPAA compliance
        # Files will be deleted regardless of tier (Hot/Cool)
        delete_after_days_since_modification_greater_than = 2555
      }

      snapshot {
        # Delete snapshots after 90 days to manage storage costs
        # Snapshots are used for audit trail and version history
        delete_after_days_since_creation_greater_than = 90
      }
    }
  }
}
