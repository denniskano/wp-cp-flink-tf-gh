terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.85.0"
    }
  }
  required_version = "~> 1.12.2"
  backend "azurerm" {}
}

provider "confluent" {
#  cloud_api_key    = var.mds_username
#  cloud_api_secret = var.mds_password
#  endpoint         = var.mds_host

  kafka_id            = var.cluster_id
  kafka_rest_endpoint = var.mds_host
  kafka_api_key       = var.mds_username
  kafka_api_secret    = var.mds_password

  schema_registry_id            = var.sr_id
  schema_registry_rest_endpoint = var.sr_rest_endpoint
  schema_registry_api_key       =  var.sr_api_key
  schema_registry_api_secret    = var.sr_api_secret
}

