terraform {
  required_version = ">= 1.5.0"

  required_providers {
    temporalcloud = {
      source  = "temporalio/temporalcloud"
      version = ">= 1.1.0"
    }
  }

  backend "azurerm" {
    # key, storage_account_name, container, access_key: terraform init -backend-config
  }
}

provider "temporalcloud" {
  api_key = var.temporal_cloud_api_key
}
