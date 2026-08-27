# Constraint Terraform + Confluent. Sin backend y sin `provider` (los declara el stack).

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}
