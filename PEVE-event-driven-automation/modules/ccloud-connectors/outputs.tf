# =============================================================================
# OUTPUTS
# =============================================================================

output "connectors" {
  description = "Mapa de conectores desplegados"
  value = {
    for name, connector in confluent_connector.connectors :
    name => {
      id     = connector.id
      name   = connector.config_nonsensitive["name"]
      status = connector.status
    }
  }
}

output "connector_ids" {
  description = "Lista de IDs de conectores"
  value       = [for connector in confluent_connector.connectors : connector.id]
}

output "connector_names" {
  description = "Lista de nombres de conectores"
  value       = [for connector in confluent_connector.connectors : connector.config_nonsensitive["name"]]
}

output "role_bindings" {
  description = "Bindings RBAC aplicados desde security/"
  value = {
    for k, b in confluent_role_binding.connector_rbac :
    k => {
      principal   = b.principal
      role_name   = b.role_name
      crn_pattern = b.crn_pattern
    }
  }
}

