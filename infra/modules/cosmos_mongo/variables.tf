variable "name_prefix" {
  description = "Prefix used for naming Cosmos resources."
  type        = string
}

variable "location" {
  description = "Azure region for Cosmos DB."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which Cosmos DB resources will reside."
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet ID used for Cosmos DB private endpoint."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID for DNS linking."
  type        = string
}

variable "account_name_suffix" {
  description = "Optional suffix appended to the Cosmos account name."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to Cosmos resources."
  type        = map(string)
}

variable "mongo_database_name" {
  description = "Name of the Mongo database to create."
  type        = string
}

variable "mongo_collection_name" {
  description = "Name of the Mongo collection to create."
  type        = string
}

variable "mongo_collection_shard_key" {
  description = "Shard key to use for the Mongo collection."
  type        = string
  default     = "_id"
}

variable "mongo_database_max_throughput" {
  description = "Autoscale max throughput (RU/s) for the Mongo database."
  type        = number
  default     = 4000
}

variable "consistency_level" {
  description = "Cosmos consistency level (Strong, BoundedStaleness, Session, Eventual, ConsistentPrefix)."
  type        = string
  default     = "Session"
}

variable "enable_automatic_failover" {
  description = "Whether automatic failover is enabled."
  type        = bool
  default     = false
}

variable "free_tier_enabled" {
  description = "Enable Cosmos free tier (dev/test only)."
  type        = bool
  default     = false
}

variable "server_version" {
  description = "Mongo server version for Cosmos DB."
  type        = string
  default     = "4.2"
}

variable "analytical_storage_enabled" {
  description = "Enable analytical storage for the Mongo database."
  type        = bool
  default     = false
}

variable "continuous_backup_enabled" {
  description = "Enable continuous backup for point-in-time restore."
  type        = bool
  default     = true
}
