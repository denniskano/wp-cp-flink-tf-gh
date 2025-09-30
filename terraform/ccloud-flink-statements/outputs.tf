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

