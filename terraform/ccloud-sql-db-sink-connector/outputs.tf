# =============================================================================
# OUTPUTS
# =============================================================================

output "connector_id" {
  description = "ID del conector SQL DB Sink creado"
  value       = confluent_connector.sql_sink.id
  sensitive   = false
}

output "connector_name" {
  description = "Nombre del conector SQL DB Sink"
  value       = confluent_connector.sql_sink.config_nonsensitive["name"]
  sensitive   = false
}

output "connector_status" {
  description = "Estado del conector"
  value       = confluent_connector.sql_sink.status
  sensitive   = false
}
