locals {
  name_prefix = lower(format("%s-%s", var.common_prefix, var.environment))

  default_tags = {
    project = "agilis-azure-hipaa"
    env     = var.environment
    owner   = "agilis"
  }

  tags = merge(local.default_tags, var.tags)

  resource_group_name = format("rg-%s-core", local.name_prefix)
}

module "resource_group" {
  source = "./modules/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  vnet_address_space  = var.vnet_address_space
  app_subnet_cidr     = var.app_subnet_cidr
  data_subnet_cidr    = var.data_subnet_cidr
  tags                = local.tags
}

module "app_service" {
  source = "./modules/app_service"

  name_prefix               = local.name_prefix
  location                  = var.location
  resource_group_name       = module.resource_group.resource_group_name
  app_service_sku_name      = var.app_service_sku_name
  app_service_plan_capacity = var.app_service_plan_capacity
  always_on                 = var.app_service_always_on
  name_suffix               = var.app_service_name_suffix
  app_settings              = var.app_service_app_settings
  connection_strings        = var.app_service_connection_strings
  subnet_id                 = module.network.app_subnet_id
  node_version              = var.app_service_node_version
  tags                      = local.tags
}

# Update App Service app_settings with Key Vault references and Application Insights after resources are created
resource "null_resource" "update_app_service_settings" {
  triggers = {
    app_service_name    = module.app_service.app_service_name
    key_vault_uri       = module.key_vault.key_vault_uri
    cosmos_secret_name  = var.key_vault_cosmos_secret_name
    storage_key_secret  = var.key_vault_storage_key_secret_name
    storage_name_secret = var.key_vault_storage_name_secret_name
    app_insights_key    = module.monitoring.application_insights_instrumentation_key
    app_insights_conn   = module.monitoring.application_insights_connection_string
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
      set -e
      APP_SERVICE="${module.app_service.app_service_name}"
      RESOURCE_GROUP="${module.resource_group.resource_group_name}"
      KV_URI="${module.key_vault.key_vault_uri}"
      COSMOS_SECRET="${var.key_vault_cosmos_secret_name}"
      STORAGE_KEY_SECRET="${var.key_vault_storage_key_secret_name}"
      STORAGE_NAME_SECRET="${var.key_vault_storage_name_secret_name}"
      APP_INSIGHTS_KEY="${module.monitoring.application_insights_instrumentation_key}"
      APP_INSIGHTS_CONN="${module.monitoring.application_insights_connection_string}"
      
      echo "Updating App Service app_settings with Key Vault references and Application Insights..."
      az webapp config appsettings set \
        --name "$APP_SERVICE" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
          COSMOS_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=$${KV_URI}secrets/$${COSMOS_SECRET}/)" \
          STORAGE_ACCOUNT_KEY="@Microsoft.KeyVault(SecretUri=$${KV_URI}secrets/$${STORAGE_KEY_SECRET}/)" \
          STORAGE_ACCOUNT_NAME="@Microsoft.KeyVault(SecretUri=$${KV_URI}secrets/$${STORAGE_NAME_SECRET}/)" \
          APPINSIGHTS_INSTRUMENTATIONKEY="$$APP_INSIGHTS_KEY" \
          APPLICATIONINSIGHTS_CONNECTION_STRING="$$APP_INSIGHTS_CONN" \
        --output none
      
      echo "App Service app_settings updated successfully."
    EOT
  }

  depends_on = [
    module.app_service,
    module.key_vault,
    module.monitoring
  ]
}

module "cosmos_mongo" {
  source = "./modules/cosmos_mongo"

  name_prefix                   = local.name_prefix
  location                      = var.location
  resource_group_name           = module.resource_group.resource_group_name
  data_subnet_id                = module.network.data_subnet_id
  virtual_network_id            = module.network.vnet_id
  account_name_suffix           = var.cosmos_account_name_suffix
  tags                          = local.tags
  mongo_database_name           = var.cosmos_mongo_database_name
  mongo_collection_name         = var.cosmos_mongo_collection_name
  mongo_collection_shard_key    = var.cosmos_mongo_collection_shard_key
  mongo_database_max_throughput = var.cosmos_mongo_database_max_throughput
  consistency_level             = var.cosmos_consistency_level
  enable_automatic_failover     = var.cosmos_enable_automatic_failover
  free_tier_enabled             = var.cosmos_free_tier_enabled
  server_version                = var.cosmos_server_version
  analytical_storage_enabled    = var.cosmos_analytical_storage_enabled
  continuous_backup_enabled     = var.cosmos_continuous_backup_enabled
}

module "storage" {
  source = "./modules/storage"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group_name      = module.resource_group.resource_group_name
  data_subnet_id           = module.network.data_subnet_id
  virtual_network_id       = module.network.vnet_id
  account_replication_type = var.storage_account_replication_type
  account_tier             = var.storage_account_tier
  container_names          = var.storage_container_names
  tags                     = local.tags
}

# Data source to get Storage account key for Key Vault
data "azurerm_storage_account" "storage" {
  name                = module.storage.storage_account_name
  resource_group_name = module.resource_group.resource_group_name
}

# Construct Cosmos DB MongoDB connection string
locals {
  cosmos_connection_string = "mongodb://${module.cosmos_mongo.account_name}:${module.cosmos_mongo.primary_key}@${module.cosmos_mongo.account_name}.mongo.cosmos.azure.net:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@${module.cosmos_mongo.account_name}@"
}

module "key_vault" {
  source = "./modules/key_vault"

  name_prefix                    = local.name_prefix
  location                       = var.location
  resource_group_name           = module.resource_group.resource_group_name
  tenant_id                      = var.tenant_id
  data_subnet_id                = module.network.data_subnet_id
  virtual_network_id            = module.network.vnet_id
  app_service_principal_id      = module.app_service.principal_id
  terraform_principal_id        = var.terraform_principal_id
  additional_rbac_assignments   = var.key_vault_additional_rbac_assignments
  sku_name                       = var.key_vault_sku_name
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  cosmos_connection_string       = local.cosmos_connection_string
  cosmos_connection_string_secret_name = var.key_vault_cosmos_secret_name
  storage_account_key            = data.azurerm_storage_account.storage.primary_access_key
  storage_account_key_secret_name = var.key_vault_storage_key_secret_name
  storage_account_name           = module.storage.storage_account_name
  storage_account_name_secret_name = var.key_vault_storage_name_secret_name
  tags                           = local.tags

  depends_on = [
    module.cosmos_mongo,
    module.storage,
    module.app_service
  ]
}

# Monitoring: Log Analytics Workspace + Application Insights + Diagnostic Settings
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group_name      = module.resource_group.resource_group_name
  retention_in_days        = var.log_analytics_retention_in_days
  app_service_id           = module.app_service.app_service_id
  cosmos_account_id        = module.cosmos_mongo.account_id
  storage_account_id       = module.storage.storage_account_id
  key_vault_id             = module.key_vault.key_vault_id
  tags                     = local.tags

  depends_on = [
    module.app_service,
    module.cosmos_mongo,
    module.storage,
    module.key_vault
  ]
}

# Azure Bastion with Windows Jump VM (optional, pay-as-you-go)
module "bastion" {
  count = var.bastion_enabled ? 1 : 0

  source = "./modules/bastion"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  virtual_network_name = module.network.vnet_name
  bastion_subnet_cidr = var.bastion_subnet_cidr
  vm_subnet_cidr      = var.bastion_vm_subnet_cidr
  vm_size              = var.bastion_vm_size
  vm_admin_username    = var.bastion_vm_admin_username
  vm_admin_password     = var.bastion_vm_admin_password != null ? var.bastion_vm_admin_password : random_password.bastion_vm_password[0].result
  auto_shutdown_enabled = var.bastion_auto_shutdown_enabled
  auto_shutdown_time    = var.bastion_auto_shutdown_time
  auto_shutdown_timezone = var.bastion_auto_shutdown_timezone
  key_vault_id          = module.key_vault.key_vault_id
  tags                  = local.tags

  depends_on = [
    module.network,
    module.key_vault
  ]
}

# Generate random password for Windows VM if not provided
resource "random_password" "bastion_vm_password" {
  count   = var.bastion_enabled && var.bastion_vm_admin_password == null ? 1 : 0
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Modules will be added incrementally. Each module will consume the shared
# locals above to keep naming, tagging, and retention policies consistent
# across every environment.
