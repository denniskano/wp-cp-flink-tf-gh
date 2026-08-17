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
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
  
  backend "azurerm" {
    # Los valores del backend deben ser hardcodeados o configurados via CLI
    # Se configurarán via: terraform init -backend-config="key=dev/PEVE/tf-flink.tfstate"
  }
}

# =============================================================================
# CONFLUENT CLOUD PROVIDER
# =============================================================================

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}
