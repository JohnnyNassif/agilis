variable "name_prefix" {
  description = "Prefix to apply to network resource names."
  type        = string
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the network resources will live."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "app_subnet_cidr" {
  description = "CIDR block for the app integration subnet."
  type        = string
}

variable "data_subnet_cidr" {
  description = "CIDR block for the data/private endpoint subnet."
  type        = string
}

variable "tags" {
  description = "Tags applied to all network resources."
  type        = map(string)
}
