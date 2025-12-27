terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.120.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  # Keep bootstrap consistent with the main `infra/` provider configuration.
  # This avoids Azure Resource Provider registration races (409 ConflictingConcurrentWriteNotAllowed)
  # that can happen frequently in brand-new subscriptions.
  skip_provider_registration = true

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

