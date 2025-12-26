locals {
  account_name            = substr(replace(format("cosmos-%s%s", var.name_prefix, var.account_name_suffix), "-", ""), 0, 44)
  database_name           = var.mongo_database_name
  collection_name         = var.mongo_collection_name
  private_endpoint_name   = format("pe-%s-cosmos", var.name_prefix)
  dns_zone_name           = "privatelink.mongo.cosmos.azure.com"
  dns_link_name           = format("pdzlnk-%s-cosmos", var.name_prefix)
  private_connection_name = format("psc-%s-cosmos", var.name_prefix)
}

resource "azurerm_cosmosdb_account" "this" {
  name                              = local.account_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  offer_type                        = "Standard"
  kind                              = "MongoDB"
  automatic_failover_enabled        = var.enable_automatic_failover
  free_tier_enabled                 = var.free_tier_enabled
  analytical_storage_enabled        = var.analytical_storage_enabled
  public_network_access_enabled     = true # Enabled - will be disabled by a script later for HIPAA compliance
  is_virtual_network_filter_enabled = true
  local_authentication_disabled     = false
  mongo_server_version              = var.server_version

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  backup {
    type                = var.continuous_backup_enabled ? "Continuous" : "Periodic"
    interval_in_minutes = var.continuous_backup_enabled ? null : 240
    retention_in_hours  = var.continuous_backup_enabled ? null : 8
  }

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_mongo_database" "this" {
  name                = local.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name

  autoscale_settings {
    max_throughput = var.mongo_database_max_throughput
  }

  lifecycle {
    ignore_changes = [throughput]
  }
}

resource "azurerm_cosmosdb_mongo_collection" "this" {
  name                = local.collection_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_mongo_database.this.name
  shard_key           = var.mongo_collection_shard_key

  index {
    keys   = [var.mongo_collection_shard_key]
    unique = false
  }

  # Ignore changes to index - Cosmos DB automatically creates a unique _id index
  # Terraform should not try to manage this automatic index
  lifecycle {
    ignore_changes = [index]
  }
}

resource "azurerm_private_dns_zone" "cosmos" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos" {
  name                  = local.dns_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = local.private_connection_name
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }

  private_dns_zone_group {
    name                 = format("pdzg-%s-cosmos", var.name_prefix)
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
  }
}
