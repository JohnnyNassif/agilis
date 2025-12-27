# ============================================================================
# App Service Managed Identity RBAC Assignments
# ============================================================================

# Grant App Service managed identity access to Key Vault (Key Vault Secrets User)
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "app_service_key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_service_principal_id
}

# Grant App Service managed identity access to Storage Account blobs (read/write at storage account scope)
# This enables Managed Identity + RBAC access without using storage account keys.
resource "azurerm_role_assignment" "app_service_storage_blob_data_contributor" {
  count = (var.app_service_principal_id != null && var.storage_account_id != null) ? 1 : 0

  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.app_service_principal_id
}

# ============================================================================
# Bastion VM Managed Identity RBAC Assignments
# ============================================================================

# Grant Bastion VM managed identity access to Key Vault (Key Vault Secrets User)
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "vm_key_vault_secrets_user" {
  count                = var.bastion_enabled ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.bastion_vm_principal_id
}

# Grant Bastion VM managed identity access to Storage Account (Storage Blob Data Contributor)
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "vm_storage_blob_data_contributor" {
  count                = var.bastion_enabled ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.bastion_vm_principal_id
}

# Grant Bastion VM managed identity access to Cosmos DB (Cosmos DB Account Reader Role)
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "vm_cosmos_db_account_reader" {
  count                = var.bastion_enabled ? 1 : 0
  scope                = var.cosmos_account_id
  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = var.bastion_vm_principal_id
}

# ============================================================================
# Terraform Service Principal RBAC Assignments
# ============================================================================
# NOTE: Terraform SPN Key Vault access is now handled by the Key Vault module
# This ensures RBAC is granted before secrets are created

# ============================================================================
# Current User RBAC Assignments (for Development/Testing)
# ============================================================================
# NOTE: Current user Key Vault access is now handled by the Key Vault module
# This ensures RBAC is granted before secrets are created

# ============================================================================
# Admin Users RBAC Assignments (Client Admins)
# ============================================================================

# Grant admin users access to Key Vault (Key Vault Secrets Officer)
# Supports up to 3 admin users for the client account
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "admin_users_key_vault_secrets_officer" {
  for_each = var.enable_admin_users ? {
    for idx, admin in var.admin_user_principal_ids :
    tostring(idx) => admin
  } : {}

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

# Grant admin users Contributor role on Resource Group (for Azure Portal access)
# This allows admins to manage resources via Azure Portal
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "admin_users_resource_group_contributor" {
  for_each = var.enable_admin_users ? {
    for idx, admin in var.admin_user_principal_ids :
    tostring(idx) => admin
  } : {}

  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

# Grant admin users Reader role on Subscription (for visibility across resources)
# This allows admins to view all resources in the subscription
# Note: Azure auto-generates UUID for the name field
resource "azurerm_role_assignment" "admin_users_subscription_reader" {
  for_each = var.enable_admin_users && var.subscription_id != null ? {
    for idx, admin in var.admin_user_principal_ids :
    tostring(idx) => admin
  } : {}

  scope                = format("/subscriptions/%s", var.subscription_id)
  role_definition_name = "Reader"
  principal_id         = each.value
}

