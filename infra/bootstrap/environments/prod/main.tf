module "bootstrap_prod" {
  source = "../../"

  subscription_id                  = var.subscription_id
  tenant_id                        = var.tenant_id
  environment                      = var.environment
  location                         = var.location
  common_prefix                    = var.common_prefix
  tags                             = var.tags
  storage_account_replication_type = var.storage_account_replication_type
  storage_account_public_network_access_enabled = var.storage_account_public_network_access_enabled
}
