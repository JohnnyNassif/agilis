terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.111"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_certificates_on_destroy = false
      purge_soft_deleted_secrets_on_destroy      = false
      purge_soft_deleted_keys_on_destroy         = false
    }
  }

  skip_provider_registration = true
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
}
