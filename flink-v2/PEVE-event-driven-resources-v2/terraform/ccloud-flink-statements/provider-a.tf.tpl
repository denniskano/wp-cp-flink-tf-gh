# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
  backend "azurerm" {
  }
}
# =============================================================================
# CONFLUENT CLOUD PROVIDER
# =============================================================================
provider "confluent" {
  schema_registry_id            = var.sr_id
  schema_registry_rest_endpoint = var.sr_rest_endpoint
  schema_registry_api_key       =  var.sr_api_key
  schema_registry_api_secret    = var.sr_api_secret
}
