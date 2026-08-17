# =============================================================================
# OUTPUTS
# =============================================================================

output "ddl_statements" {
  description = "Lista de statements DDL aplicados exitosamente (claves for_each = statement-name o stem del archivo)"
  value       = sort(keys(confluent_flink_statement.ddl_statements))
  sensitive   = false
}

output "dml_statements" {
  description = "Lista de statements DML aplicados exitosamente (claves for_each = statement-name o stem del archivo)"
  value       = sort(keys(confluent_flink_statement.dml_statements))
  sensitive   = false
}

output "all_statements" {
  description = "Lista completa de todos los statements aplicados"
  value = sort(concat(
    keys(confluent_flink_statement.ddl_statements),
    keys(confluent_flink_statement.dml_statements)
  ))
  sensitive = false
}
