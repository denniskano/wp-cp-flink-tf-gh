terraform {
  required_version = ">= 1.5.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }

  backend "azurerm" {
    # key, storage_account_name, container, access_key: terraform init -backend-config
  }
}

provider "confluent" {
  cloud_api_key                 = var.confluent_cloud_api_key
  cloud_api_secret              = var.confluent_cloud_api_secret
  schema_registry_id            = var.sr_id
  schema_registry_rest_endpoint = var.sr_rest_endpoint
  schema_registry_api_key       = var.sr_api_key
  schema_registry_api_secret    = var.sr_api_secret
}
