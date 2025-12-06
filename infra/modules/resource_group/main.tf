variable "name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region where the resource group will live."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resource group."
  type        = map(string)
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
