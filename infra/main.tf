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

  name_prefix                 = local.name_prefix
  location                    = var.location
  resource_group_name         = module.resource_group.resource_group_name
  app_service_sku_name        = var.app_service_sku_name
  app_service_plan_capacity   = var.app_service_plan_capacity
  app_settings                = var.app_service_app_settings
  connection_strings          = var.app_service_connection_strings
  subnet_id                   = module.network.app_subnet_id
  node_version                = var.app_service_node_version
  tags                        = local.tags
}

module "cosmos_mongo" {
  source = "./modules/cosmos_mongo"

  name_prefix                    = local.name_prefix
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group_name
  data_subnet_id                 = module.network.data_subnet_id
  virtual_network_id             = module.network.vnet_id
  account_name_suffix            = var.cosmos_account_name_suffix
  tags                           = local.tags
  mongo_database_name            = var.cosmos_mongo_database_name
  mongo_collection_name          = var.cosmos_mongo_collection_name
  mongo_collection_shard_key     = var.cosmos_mongo_collection_shard_key
  mongo_database_max_throughput  = var.cosmos_mongo_database_max_throughput
  consistency_level              = var.cosmos_consistency_level
  enable_automatic_failover      = var.cosmos_enable_automatic_failover
  free_tier_enabled              = var.cosmos_free_tier_enabled
  server_version                 = var.cosmos_server_version
  analytical_storage_enabled     = var.cosmos_analytical_storage_enabled
  continuous_backup_enabled      = var.cosmos_continuous_backup_enabled
}

# Modules will be added incrementally. Each module will consume the shared
# locals above to keep naming, tagging, and retention policies consistent
# across every environment.
