terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.32.0"
    }
  }
  required_version = "~> 1.12.2"
  backend "azurerm" {}
}

provider "confluent" {
}

