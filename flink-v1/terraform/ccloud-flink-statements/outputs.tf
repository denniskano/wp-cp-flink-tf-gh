# =============================================================================
# OUTPUTS
# =============================================================================

output "ddl_statements" {
  description = "DDL managed (claves for_each = statement-name)"
  value       = sort(keys(confluent_flink_statement.ddl_statements))
  sensitive   = false
}

output "dml_statements" {
  description = "DML managed (claves for_each = statement-name)"
  value       = sort(keys(confluent_flink_statement.dml_statements))
  sensitive   = false
}

output "ddl_once" {
  description = "DDL apply: once (marcador en state; no se re-crean)"
  value       = sort(keys(terraform_data.ddl_once))
  sensitive   = false
}

output "dml_once" {
  description = "DML apply: once (marcador en state; no se re-crean)"
  value       = sort(keys(terraform_data.dml_once))
  sensitive   = false
}

output "ddl_ignored" {
  description = "DDL apply: ignore (Terraform no los gestiona)"
  value       = sort(keys(local.ddl_ignored))
  sensitive   = false
}

output "dml_ignored" {
  description = "DML apply: ignore (Terraform no los gestiona)"
  value       = sort(keys(local.dml_ignored))
  sensitive   = false
}

output "all_statements" {
  description = "Statements que Terraform gestiona este apply (managed + once)"
  value = sort(concat(
    keys(confluent_flink_statement.ddl_statements),
    keys(confluent_flink_statement.dml_statements),
    keys(terraform_data.ddl_once),
    keys(terraform_data.dml_once)
  ))
  sensitive = false
}
