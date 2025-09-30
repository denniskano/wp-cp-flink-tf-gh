# =============================================================================
# OUTPUTS
# =============================================================================

output "compute_pool_ids" {
  description = "Map of compute pool names to their IDs"
  value = {
    for name, pool in confluent_flink_compute_pool.this : name => pool.id
  }
}

output "compute_pool_configs" {
  description = "Full configuration of all compute pools"
  value = {
    for name, pool in confluent_flink_compute_pool.this : name => {
      id            = pool.id
      display_name  = pool.display_name
      cloud         = pool.cloud
      region        = pool.region
      max_cfu       = pool.max_cfu
      environment_id = pool.environment[0].id
      resource_name = pool.resource_name
    }
  }
}
