# =============================================================================
# COMPUTE POOLS MODULE
# =============================================================================

# Load configuration from YAML file
locals {
  config = yamldecode(file(var.compute_pool_config_path))
}

# Flink Compute Pools
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
