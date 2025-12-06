terraform {
  backend "azurerm" {
    resource_group_name  = "rg-agilis-prod-tfstate"
    storage_account_name = "agilisprodstate21gt"
    container_name       = "tfstate"
    key                  = "agilis/prod/terraform.tfstate"
  }
}
