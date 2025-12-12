variable "name_prefix" {
  description = "Prefix applied to state resources."
  type        = string
}

variable "location" {
  description = "Azure region for state resources."
  type        = string
}

variable "tags" {
  description = "Tags to apply to each resource."
  type        = map(string)
}

variable "storage_account_replication_type" {
  description = "Replication type (LRS/ZRS/etc)."
  type        = string
  default     = "ZRS"
}

variable "storage_account_public_network_access_enabled" {
  description = "Whether public network access should be enabled."
  type        = bool
  default     = true
}

resource "azurerm_resource_group" "state" {
  name     = format("rg-%s-tfstate", var.name_prefix)
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                          = replace(substr(format("%sstate%s", var.name_prefix, random_string.suffix.result), 0, 24), "-", "")
  resource_group_name           = azurerm_resource_group.state.name
  location                      = azurerm_resource_group.state.location
  account_tier                  = "Standard"
  account_replication_type      = var.storage_account_replication_type
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = var.storage_account_public_network_access_enabled
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}
