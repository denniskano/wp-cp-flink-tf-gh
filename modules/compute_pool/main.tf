# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Cargar configuración desde archivo YAML
  config = try(yamldecode(file(var.compute_pool_config_path)), {})
}

# =============================================================================
# RESOURCES
# =============================================================================
resource "confluent_flink_compute_pool" "this" {
  display_name = var.compute_pool_name

  environment {
    id = var.environment_id
  }

  cloud  = coalesce(try(local.config.cloud, null), var.cloud)
  region = var.region
  max_cfu = try(local.config.max_cfu, 5)
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "compute_pool_id" {
  description = "ID del Flink compute pool creado"
  value       = confluent_flink_compute_pool.this.id
  sensitive   = false
}


