# =============================================================================
# OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# Compute Pool Outputs
# -----------------------------------------------------------------------------
output "compute_pool_id" {
  description = "ID del Flink compute pool creado"
  value       = module.compute_pool.compute_pool_id
  sensitive   = false
}

# -----------------------------------------------------------------------------
# Flink Statements Outputs
# -----------------------------------------------------------------------------
output "ddl_statements" {
  description = "Lista de statements DDL aplicados exitosamente"
  value       = module.flink_statements.ddl_statements
  sensitive   = false
}

output "dml_statements" {
  description = "Lista de statements DML aplicados exitosamente"
  value       = module.flink_statements.dml_statements
  sensitive   = false
}

output "all_statements" {
  description = "Lista completa de todos los statements aplicados"
  value       = module.flink_statements.all_statements
  sensitive   = false
}


