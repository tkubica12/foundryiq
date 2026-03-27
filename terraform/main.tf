terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}

provider "azapi" {
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length      = 5
  special     = false
  upper       = false
  numeric     = true
  min_numeric = 5
}

locals {
  suffix   = random_string.suffix.result
  location = "swedencentral"
  tags = {
    Environment     = "demo"
    Project         = "FoundryIQ"
    SecurityControl = "ignore"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-foundryiq-demo-sc"
  location = local.location
  tags     = local.tags
}
