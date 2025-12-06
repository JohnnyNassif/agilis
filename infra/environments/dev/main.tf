module "agilis_dev" {
  source = "../../"

  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  environment                     = var.environment
  location                        = var.location
  common_prefix                   = var.common_prefix
  tags                            = var.tags
  log_analytics_retention_in_days = var.log_analytics_retention_in_days
  archive_after_days              = var.archive_after_days
  app_service_sku_name            = var.app_service_sku_name
  cosmos_mongo_database_max_throughput = var.cosmos_mongo_database_max_throughput
  cosmos_free_tier_enabled             = var.cosmos_free_tier_enabled
  cosmos_enable_automatic_failover     = var.cosmos_enable_automatic_failover
  cosmos_account_name_suffix           = var.cosmos_account_name_suffix
}
