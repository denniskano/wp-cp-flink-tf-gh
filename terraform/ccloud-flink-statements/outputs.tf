# =============================================================================
# OUTPUTS
# =============================================================================

output "ddl_statements" {
  description = "Lista de statements DDL aplicados exitosamente"
  value       = [for i, v in confluent_flink_statement.ddl_statements : local.ddl_data[i]["statement-name"]]
  sensitive   = false
}

output "dml_statements" {
  description = "Lista de statements DML aplicados exitosamente"
  value       = [for i, v in confluent_flink_statement.dml_statements : local.dml_data[i]["statement-name"]]
  sensitive   = false
}

output "all_statements" {
  description = "Lista completa de todos los statements aplicados"
  value = concat(
    [for i, v in confluent_flink_statement.ddl_statements : local.ddl_data[i]["statement-name"]],
    [for i, v in confluent_flink_statement.dml_statements : local.dml_data[i]["statement-name"]]
  )
  sensitive = false
}

# DEBUG OUTPUTS
output "debug_ddl_files" {
  description = "Debug: archivos DDL detectados"
  value       = local.ddl_files
}

output "debug_dml_files" {
  description = "Debug: archivos DML detectados"
  value       = local.dml_files
}

output "debug_compute_pools" {
  description = "Debug: compute pools detectados"
  value       = local.all_compute_pools
}

output "debug_flink_credentials" {
  description = "Debug: credenciales Flink"
  value       = {
    flink_key_exists = local.confluent_flink_api_key != ""
    flink_secret_exists = local.confluent_flink_api_secret != ""
    principal_exists = local.principal_id != ""
    flink_key_length = length(local.confluent_flink_api_key)
    flink_secret_length = length(local.confluent_flink_api_secret)
    principal_length = length(local.principal_id)
    flink_key_start = substr(local.confluent_flink_api_key, 0, 8)
    principal_start = substr(local.principal_id, 0, 8)
  }
  sensitive = true
}
