terraform {
  backend "azurerm" {
    resource_group_name  = "rg-agilis-dev-tfstate"
    storage_account_name = "agilisdevstatedpm8"
    container_name       = "tfstate"
    key                  = "agilis/dev/terraform.tfstate"
  }
}
