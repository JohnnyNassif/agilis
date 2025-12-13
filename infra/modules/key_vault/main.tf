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

resource "azurerm_key_vault" "this" {
  name                       = local.vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  public_network_access_enabled = false
  tags                       = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  # Enable RBAC for access control (modern approach)
  enable_rbac_authorization = true
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

# Grant App Service managed identity access to Key Vault (Key Vault Secrets User)
resource "azurerm_role_assignment" "app_service_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_service_principal_id
}

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

# Grant current Azure CLI user access to Key Vault for secret creation
# This is done via Azure CLI since we need to detect the current user
resource "null_resource" "grant_current_user_access" {
  triggers = {
    vault_id = azurerm_key_vault.this.id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      VAULT_NAME="${azurerm_key_vault.this.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      VAULT_ID="${azurerm_key_vault.this.id}"
      
      echo "Granting current user Key Vault Secrets Officer role..."
      CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
      
      if [ -z "$CURRENT_USER_ID" ]; then
        echo "Error: Could not detect current user."
        echo "Please grant yourself 'Key Vault Secrets Officer' role manually:"
        echo "  az role assignment create --scope $VAULT_ID --role 'Key Vault Secrets Officer' --assignee <your-user-id>"
        exit 1
      fi
      
      # Create role assignment (ignore if already exists)
      az role assignment create \
        --scope "$VAULT_ID" \
        --role "Key Vault Secrets Officer" \
        --assignee "$CURRENT_USER_ID" \
        --output none 2>/dev/null || echo "Role assignment may already exist, continuing..."
      
      echo "Waiting for RBAC role propagation (this can take up to 5 minutes)..."
      # Wait longer for RBAC propagation - Azure can take up to 5 minutes
      sleep 60
      
      # Verify role assignment exists
      echo "Verifying role assignment..."
      ROLE_ASSIGNMENT=$(az role assignment list \
        --scope "$VAULT_ID" \
        --assignee "$CURRENT_USER_ID" \
        --role "Key Vault Secrets Officer" \
        --query "[0].id" -o tsv 2>/dev/null || echo "")
      
      if [ -z "$ROLE_ASSIGNMENT" ]; then
        echo "Warning: Role assignment not found. Waiting additional time..."
        sleep 120
      else
        echo "Role assignment confirmed: $ROLE_ASSIGNMENT"
      fi
    EOT
  }

  depends_on = [
    azurerm_key_vault.this,
    azurerm_private_endpoint.key_vault
  ]
}

# Store Cosmos DB connection string in Key Vault using Azure CLI
# This bypasses RBAC issues by using the authenticated Azure CLI session
resource "null_resource" "cosmos_connection_string_secret" {
  count = var.cosmos_connection_string != null ? 1 : 0

  triggers = {
    vault_name    = azurerm_key_vault.this.name
    secret_name   = var.cosmos_connection_string_secret_name
    secret_value  = sha256(var.cosmos_connection_string)
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      VAULT_NAME="${azurerm_key_vault.this.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      SECRET_NAME="${var.cosmos_connection_string_secret_name}"
      SECRET_VALUE="${var.cosmos_connection_string}"
      
      echo "Temporarily enabling public access for secret creation..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Enabled \
        --output none
      
      sleep 5
      
      echo "Storing Cosmos connection string in Key Vault (with retry logic)..."
      MAX_RETRIES=10
      RETRY_DELAY=30
      RETRY_COUNT=0
      
      while [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; do
        if az keyvault secret set \
          --vault-name "$$VAULT_NAME" \
          --name "$$SECRET_NAME" \
          --value "$$SECRET_VALUE" \
          --output none 2>/dev/null; then
          echo "Cosmos connection string stored successfully."
          break
        else
          let RETRY_COUNT=RETRY_COUNT+1
          if [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; then
            echo "Attempt $$RETRY_COUNT failed. Waiting $$RETRY_DELAY seconds for RBAC propagation..."
            sleep $$RETRY_DELAY
          else
            echo "Error: Failed to store secret after $$MAX_RETRIES attempts."
            echo "RBAC role may not have propagated yet. Please wait a few minutes and retry."
            exit 1
          fi
        fi
      done
      
      echo "Disabling public access to restore HIPAA compliance..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled \
        --output none
    EOT
  }

  depends_on = [
    azurerm_key_vault.this,
    azurerm_private_endpoint.key_vault,
    null_resource.grant_current_user_access
  ]
}

# Store Storage Account key in Key Vault using Azure CLI
resource "null_resource" "storage_account_key_secret" {
  count = var.storage_account_key != null ? 1 : 0

  triggers = {
    vault_name    = azurerm_key_vault.this.name
    secret_name   = var.storage_account_key_secret_name
    secret_value  = sha256(var.storage_account_key)
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      VAULT_NAME="${azurerm_key_vault.this.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      SECRET_NAME="${var.storage_account_key_secret_name}"
      SECRET_VALUE="${var.storage_account_key}"
      
      echo "Temporarily enabling public access for secret creation..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Enabled \
        --output none
      
      sleep 5
      
      echo "Storing Storage account key in Key Vault (with retry logic)..."
      MAX_RETRIES=10
      RETRY_DELAY=30
      RETRY_COUNT=0
      
      while [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; do
        if az keyvault secret set \
          --vault-name "$$VAULT_NAME" \
          --name "$$SECRET_NAME" \
          --value "$$SECRET_VALUE" \
          --output none 2>/dev/null; then
          echo "Storage account key stored successfully."
          break
        else
          let RETRY_COUNT=RETRY_COUNT+1
          if [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; then
            echo "Attempt $$RETRY_COUNT failed. Waiting $$RETRY_DELAY seconds for RBAC propagation..."
            sleep $$RETRY_DELAY
          else
            echo "Error: Failed to store secret after $$MAX_RETRIES attempts."
            echo "RBAC role may not have propagated yet. Please wait a few minutes and retry."
            exit 1
          fi
        fi
      done
      
      echo "Disabling public access to restore HIPAA compliance..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled \
        --output none
    EOT
  }

  depends_on = [
    azurerm_key_vault.this,
    azurerm_private_endpoint.key_vault,
    null_resource.grant_current_user_access
  ]
}

# Store Storage Account name in Key Vault using Azure CLI
resource "null_resource" "storage_account_name_secret" {
  count = var.storage_account_name != null ? 1 : 0

  triggers = {
    vault_name    = azurerm_key_vault.this.name
    secret_name   = var.storage_account_name_secret_name
    secret_value  = var.storage_account_name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      VAULT_NAME="${azurerm_key_vault.this.name}"
      RESOURCE_GROUP="${var.resource_group_name}"
      SECRET_NAME="${var.storage_account_name_secret_name}"
      SECRET_VALUE="${var.storage_account_name}"
      
      echo "Temporarily enabling public access for secret creation..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Enabled \
        --output none
      
      sleep 5
      
      echo "Storing Storage account name in Key Vault (with retry logic)..."
      MAX_RETRIES=10
      RETRY_DELAY=30
      RETRY_COUNT=0
      
      while [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; do
        if az keyvault secret set \
          --vault-name "$$VAULT_NAME" \
          --name "$$SECRET_NAME" \
          --value "$$SECRET_VALUE" \
          --output none 2>/dev/null; then
          echo "Storage account name stored successfully."
          break
        else
          let RETRY_COUNT=RETRY_COUNT+1
          if [ $$RETRY_COUNT -lt $$MAX_RETRIES ]; then
            echo "Attempt $$RETRY_COUNT failed. Waiting $$RETRY_DELAY seconds for RBAC propagation..."
            sleep $$RETRY_DELAY
          else
            echo "Error: Failed to store secret after $$MAX_RETRIES attempts."
            echo "RBAC role may not have propagated yet. Please wait a few minutes and retry."
            exit 1
          fi
        fi
      done
      
      echo "Disabling public access to restore HIPAA compliance..."
      az keyvault update \
        --name "$VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled \
        --output none
    EOT
  }

  depends_on = [
    azurerm_key_vault.this,
    azurerm_private_endpoint.key_vault,
    null_resource.grant_current_user_access
  ]
}

