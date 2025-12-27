locals {
  vault_name              = substr(replace(format("kv-%s-%s", var.name_prefix, random_string.suffix.result), "-", ""), 0, 24)
  private_endpoint_name   = format("pe-%s-kv", var.name_prefix)
  dns_zone_name           = "privatelink.vaultcore.azure.net"
  dns_link_name           = format("pdzlnk-%s-kv", var.name_prefix)
  private_connection_name = format("psc-%s-kv", var.name_prefix)
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# Create Key Vault with public access enabled initially for provisioning
# Public access will be disabled after secrets are created (HIPAA compliance)
resource "azurerm_key_vault" "this" {
  name                          = local.vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = true # Enabled - will be disabled manually later for HIPAA compliance
  tags                          = var.tags

  network_acls {
    default_action = "Allow" # Allow - will be changed to Deny manually later for HIPAA compliance
    bypass         = "AzureServices"
  }

  # Enable RBAC for access control (modern approach)
  enable_rbac_authorization = true

  lifecycle {
    # HIPAA hardening may disable public network access and tighten network ACLs post-deploy.
    # Do not let Terraform revert manual hardening.
    ignore_changes = [
      public_network_access_enabled,
      network_acls,
    ]
  }
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = local.dns_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = local.private_connection_name
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = format("pdzg-%s-kv", var.name_prefix)
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}

# RBAC assignments for App Service managed identity are now handled by the RBAC module
# This ensures centralized RBAC management

# Grant Terraform service principal access (Key Vault Secrets Officer for secret management)
resource "azurerm_role_assignment" "terraform_secrets_officer" {
  count                = var.terraform_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.terraform_principal_id
}

# Grant additional users/groups RBAC access to Key Vault
resource "azurerm_role_assignment" "additional_users" {
  for_each = {
    for idx, assignment in var.additional_rbac_assignments :
    "${assignment.principal_id}-${assignment.role_definition_name}" => assignment
  }

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# Get current Azure client configuration (for current user's object ID)
# This is needed to grant RBAC permissions to the user running Terraform
data "azurerm_client_config" "current" {}

# Grant current user access to Key Vault (Key Vault Secrets Officer)
# Secrets are created in root module after RBAC propagates
# In production, set enable_current_user_access = false and use terraform_principal_id instead
resource "azurerm_role_assignment" "current_user_secrets_officer" {
  count                = var.enable_current_user_access ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Secrets are now created separately in root main.tf after Cosmos/Storage are ready
# This allows Key Vault + RBAC to be created first, giving RBAC time to propagate
# naturally while Cosmos/Storage are being created (5-10+ minutes)

