terraform {
  required_version = ">= 1.5.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}

# Configuración de Confluent
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Configuración local desde archivo PEVE
locals {
  config = yamldecode(file(var.compute_pool_config_path))
}

# Recurso de Flink Compute Pool
resource "confluent_flink_compute_pool" "this" {
  for_each = {
    for idx, pool in try(local.config.compute_pools, []) : pool.pool_name => pool
  }

  display_name = each.value.pool_name

  environment {
    id = var.environment_id
  }

  cloud   = each.value.cloud
  region  = each.value.region
  max_cfu = each.value.max_cfu
}
