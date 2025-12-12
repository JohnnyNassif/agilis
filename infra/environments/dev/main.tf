module "agilis_dev" {
  source = "../../"

  subscription_id                      = var.subscription_id
  tenant_id                            = var.tenant_id
  environment                          = var.environment
  location                             = var.location
  common_prefix                        = var.common_prefix
  tags                                 = var.tags
  log_analytics_retention_in_days      = var.log_analytics_retention_in_days
  archive_after_days                   = var.archive_after_days
  app_service_sku_name                 = var.app_service_sku_name
  app_service_always_on                = var.app_service_always_on
  cosmos_mongo_database_max_throughput = var.cosmos_mongo_database_max_throughput
  cosmos_free_tier_enabled             = var.cosmos_free_tier_enabled
  cosmos_enable_automatic_failover     = var.cosmos_enable_automatic_failover
  cosmos_account_name_suffix           = var.cosmos_account_name_suffix
  app_service_name_suffix              = var.app_service_name_suffix
  storage_account_replication_type     = var.storage_account_replication_type
  storage_account_tier                 = var.storage_account_tier
  storage_container_names              = var.storage_container_names
  key_vault_sku_name                   = var.key_vault_sku_name
  key_vault_soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  key_vault_purge_protection_enabled   = var.key_vault_purge_protection_enabled
  terraform_principal_id               = var.terraform_principal_id
}
