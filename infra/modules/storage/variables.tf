variable "name_prefix" {
  description = "Prefix used for naming the storage account and resources."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the storage resources reside."
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet ID used for the storage private endpoint."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID for DNS linking."
  type        = string
}

variable "account_replication_type" {
  description = "Storage account replication type (e.g., LRS, ZRS)."
  type        = string
  default     = "ZRS"
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)."
  type        = string
  default     = "Standard"
}

variable "account_kind" {
  description = "Storage account kind."
  type        = string
  default     = "StorageV2"
}

variable "container_names" {
  description = "List of blob container names to create."
  type        = list(string)
  default     = ["phi-files"]
}

variable "tags" {
  description = "Tags to apply to storage resources."
  type        = map(string)
}
