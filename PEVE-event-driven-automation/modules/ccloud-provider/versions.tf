# Provider Confluent (constraint). El `provider "confluent"` vive en cada stack.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}
