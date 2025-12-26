locals {
  # Policy assignment scope - use management group if provided, otherwise subscription
  assignment_scope = var.management_group_id != null ? "/providers/Microsoft.Management/managementGroups/${var.management_group_id}" : local.subscription_id_formatted

  # Common policy parameters
  common_parameters = {
    effect = "Audit" # Use Audit mode initially, can be changed to Deny for enforcement
  }
}

# ============================================================================
# HIPAA Compliance Policy Initiative Assignment
# ============================================================================

# Assign Azure HIPAA/HITRUST compliance initiative
# This is a built-in Azure Policy initiative that includes multiple HIPAA-related policies
# Note: The HIPAA initiative may not be available in all subscriptions (requires Azure Security Center)
# If not available, only custom policies will be assigned (which is sufficient for HIPAA compliance)
# IMPORTANT: Only enable this if you know the HIPAA initiative is available in your subscription
data "azurerm_policy_set_definition" "hipaa" {
  count        = var.enable_hipaa_initiative ? 1 : 0
  display_name = "HIPAA HITRUST"

  # Try to find the HIPAA initiative - it may have different names in different subscriptions
  # Common names: "HIPAA HITRUST", "HIPAA", "HITRUST"
  # If this data source fails, Terraform will error - disable enable_hipaa_initiative if not available
}

locals {
  # Format subscription ID correctly (must be /subscriptions/{id})
  subscription_id_formatted = startswith(var.subscription_id, "/subscriptions/") ? var.subscription_id : "/subscriptions/${var.subscription_id}"

  # Get HIPAA initiative ID if available
  hipaa_initiative_id = var.enable_hipaa_initiative && length(data.azurerm_policy_set_definition.hipaa) > 0 ? data.azurerm_policy_set_definition.hipaa[0].id : null
}

resource "azurerm_subscription_policy_assignment" "hipaa_initiative" {
  count                = var.enable_hipaa_initiative && var.management_group_id == null && local.hipaa_initiative_id != null ? 1 : 0
  name                 = "hipaa-hitrust-compliance"
  display_name         = "HIPAA HITRUST Compliance Initiative"
  description          = "Assigns Azure HIPAA/HITRUST compliance policy initiative for continuous compliance enforcement"
  policy_definition_id = local.hipaa_initiative_id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus" # Required for managed identity

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    # You can customize parameters here if needed
  })
}

resource "azurerm_management_group_policy_assignment" "hipaa_initiative" {
  count                = var.enable_hipaa_initiative && var.management_group_id != null && local.hipaa_initiative_id != null ? 1 : 0
  name                 = "hipaa-hitrust-compliance"
  display_name         = "HIPAA HITRUST Compliance Initiative"
  description          = "Assigns Azure HIPAA/HITRUST compliance policy initiative for continuous compliance enforcement"
  policy_definition_id = local.hipaa_initiative_id
  management_group_id  = var.management_group_id
  location             = "eastus" # Required for managed identity

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    # You can customize parameters here if needed
  })
}

# ============================================================================
# Custom HIPAA-Specific Policy Definitions
# ============================================================================

# Policy 1: Enforce Private Endpoints on Storage Accounts
# Checks if public network access is enabled (indicates private endpoints may not be properly configured)
resource "azurerm_policy_definition" "storage_private_endpoint" {
  count        = var.enable_custom_policies ? 1 : 0
  name         = format("enforce-storage-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "HIPAA: Storage Accounts should use private endpoints"
  description  = "This policy enforces that Storage Accounts have public network access disabled (indicating private endpoints are used) for HIPAA compliance."

  metadata = jsonencode({
    category = "HIPAA Compliance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })
}

# Policy 2: Enforce Private Endpoints on Key Vault
resource "azurerm_policy_definition" "keyvault_private_endpoint" {
  count        = var.enable_custom_policies ? 1 : 0
  name         = format("enforce-keyvault-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "HIPAA: Key Vaults should use private endpoints"
  description  = "This policy enforces that Key Vaults have private endpoints configured for HIPAA compliance."

  metadata = jsonencode({
    category = "HIPAA Compliance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.KeyVault/vaults"
        },
        {
          field     = "Microsoft.KeyVault/vaults/networkAcls.defaultAction"
          notEquals = "Deny"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })
}

# Policy 3: Enforce Private Endpoints on Cosmos DB
resource "azurerm_policy_definition" "cosmos_private_endpoint" {
  count        = var.enable_custom_policies ? 1 : 0
  name         = format("enforce-cosmos-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "HIPAA: Cosmos DB accounts should use private endpoints"
  description  = "This policy enforces that Cosmos DB accounts have private endpoints configured for HIPAA compliance."

  metadata = jsonencode({
    category = "HIPAA Compliance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.DocumentDB/databaseAccounts"
        },
        {
          field     = "Microsoft.DocumentDB/databaseAccounts/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })
}

# Policy 4: Enforce Infrastructure Encryption on Storage Accounts
resource "azurerm_policy_definition" "storage_infrastructure_encryption" {
  count        = var.enable_custom_policies ? 1 : 0
  name         = format("enforce-storage-infrastructure-encryption-%s", replace(var.name_prefix, "-", ""))
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "HIPAA: Storage Accounts should have infrastructure encryption enabled"
  description  = "This policy enforces that Storage Accounts have infrastructure encryption (double encryption) enabled for HIPAA compliance."

  metadata = jsonencode({
    category = "HIPAA Compliance"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "Microsoft.Storage/storageAccounts/encryption.services.blob.enabled"
          equals = "true"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/encryption.requireInfrastructureEncryption"
          notEquals = "true"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
    }
  })
}

# Policy 5: Enforce Diagnostic Settings on Key Resources
# Note: log_analytics_workspace_id is always provided from monitoring module
resource "azurerm_policy_definition" "diagnostic_settings" {
  count        = var.enable_custom_policies ? 1 : 0
  name         = format("enforce-diagnostic-settings-hipaa-%s", replace(var.name_prefix, "-", ""))
  policy_type  = "Custom"
  mode         = "All"
  display_name = "HIPAA: Diagnostic settings should be enabled for HIPAA resources"
  description  = "This policy enforces that diagnostic settings are enabled for Storage Accounts, Key Vaults, and Cosmos DB accounts for HIPAA compliance."

  metadata = jsonencode({
    category = "HIPAA Compliance"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field  = "type"
          equals = "Microsoft.KeyVault/vaults"
        },
        {
          field  = "type"
          equals = "Microsoft.DocumentDB/databaseAccounts"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
      details = {
        type = "Microsoft.Insights/diagnosticSettings"
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/logs.enabled"
              equals = "true"
            },
            {
              field  = "Microsoft.Insights/diagnosticSettings/workspaceId"
              equals = "[parameters('logAnalyticsWorkspaceId')]"
            }
          ]
        }
      }
    }
  })

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      type = "String"
      metadata = {
        displayName = "Log Analytics Workspace ID"
        description = "The Log Analytics Workspace ID where diagnostic logs should be sent"
      }
      defaultValue = var.log_analytics_workspace_id
    }
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["AuditIfNotExists", "Disabled"]
      defaultValue  = "AuditIfNotExists"
    }
  })
}

# ============================================================================
# Policy Assignments
# ============================================================================

# Assign Storage Private Endpoint Policy
resource "azurerm_subscription_policy_assignment" "storage_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id == null ? 1 : 0
  name                 = format("assign-storage-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Storage Account Private Endpoints"
  description          = "Assigns policy to enforce private endpoints on Storage Accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.storage_private_endpoint[0].id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit" # Start with Audit, can change to Deny later
    }
  })
}

# Assign Key Vault Private Endpoint Policy
resource "azurerm_subscription_policy_assignment" "keyvault_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id == null ? 1 : 0
  name                 = format("assign-keyvault-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Key Vault Private Endpoints"
  description          = "Assigns policy to enforce private endpoints and network restrictions on Key Vaults for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.keyvault_private_endpoint[0].id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Assign Cosmos DB Private Endpoint Policy
resource "azurerm_subscription_policy_assignment" "cosmos_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id == null ? 1 : 0
  name                 = format("assign-cosmos-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Cosmos DB Private Endpoints"
  description          = "Assigns policy to enforce private endpoints on Cosmos DB accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.cosmos_private_endpoint[0].id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Assign Storage Infrastructure Encryption Policy
resource "azurerm_subscription_policy_assignment" "storage_infrastructure_encryption" {
  count                = var.enable_custom_policies && var.management_group_id == null ? 1 : 0
  name                 = format("assign-storage-infrastructure-encryption-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Storage Account Infrastructure Encryption"
  description          = "Assigns policy to enforce infrastructure encryption (double encryption) on Storage Accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.storage_infrastructure_encryption[0].id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Assign Diagnostic Settings Policy
# Note: log_analytics_workspace_id is always provided from monitoring module
resource "azurerm_subscription_policy_assignment" "diagnostic_settings" {
  count                = var.enable_custom_policies && var.management_group_id == null ? 1 : 0
  name                 = format("assign-diagnostic-settings-hipaa-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Diagnostic Settings"
  description          = "Assigns policy to enforce diagnostic settings on HIPAA resources for compliance monitoring"
  policy_definition_id = azurerm_policy_definition.diagnostic_settings[0].id
  subscription_id      = local.subscription_id_formatted
  location             = "eastus"

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

# Management Group assignments (if management_group_id is provided)
resource "azurerm_management_group_policy_assignment" "storage_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id != null ? 1 : 0
  name                 = format("assign-storage-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Storage Account Private Endpoints"
  description          = "Assigns policy to enforce private endpoints on Storage Accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.storage_private_endpoint[0].id
  management_group_id  = var.management_group_id
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "keyvault_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id != null ? 1 : 0
  name                 = format("assign-keyvault-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Key Vault Private Endpoints"
  description          = "Assigns policy to enforce private endpoints and network restrictions on Key Vaults for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.keyvault_private_endpoint[0].id
  management_group_id  = var.management_group_id
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "cosmos_private_endpoint" {
  count                = var.enable_custom_policies && var.management_group_id != null ? 1 : 0
  name                 = format("assign-cosmos-private-endpoint-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Cosmos DB Private Endpoints"
  description          = "Assigns policy to enforce private endpoints on Cosmos DB accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.cosmos_private_endpoint[0].id
  management_group_id  = var.management_group_id
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "storage_infrastructure_encryption" {
  count                = var.enable_custom_policies && var.management_group_id != null ? 1 : 0
  name                 = format("assign-storage-infrastructure-encryption-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Storage Account Infrastructure Encryption"
  description          = "Assigns policy to enforce infrastructure encryption (double encryption) on Storage Accounts for HIPAA compliance"
  policy_definition_id = azurerm_policy_definition.storage_infrastructure_encryption[0].id
  management_group_id  = var.management_group_id
  location             = "eastus"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

resource "azurerm_management_group_policy_assignment" "diagnostic_settings" {
  count                = var.enable_custom_policies && var.management_group_id != null ? 1 : 0
  name                 = format("assign-diagnostic-settings-hipaa-%s", replace(var.name_prefix, "-", ""))
  display_name         = "HIPAA: Enforce Diagnostic Settings"
  description          = "Assigns policy to enforce diagnostic settings on HIPAA resources for compliance monitoring"
  policy_definition_id = azurerm_policy_definition.diagnostic_settings[0].id
  management_group_id  = var.management_group_id
  location             = "eastus"

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
    effect = {
      value = "AuditIfNotExists"
    }
  })
}

