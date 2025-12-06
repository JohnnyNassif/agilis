locals {
  name_prefix = lower(format("%s-%s", var.common_prefix, var.environment))

  default_tags = {
    project = "agilis-azure-hipaa"
    env     = var.environment
    owner   = "agilis"
  }

  tags = merge(local.default_tags, var.tags)
}

module "state_backend" {
  source = "./modules/state_backend"

  name_prefix                      = local.name_prefix
  location                         = var.location
  tags                             = local.tags
  storage_account_replication_type = var.storage_account_replication_type
  storage_account_public_network_access_enabled = var.storage_account_public_network_access_enabled
}
