# State de flink-v1 (terraform/ccloud-connectors, resources en la raíz).
# Sin esto el primer plan en stacks/kafka-connect es destroy+create (se pierden offsets).
moved {
  from = confluent_connector.connectors
  to   = module.connectors.confluent_connector.connectors
}

moved {
  from = confluent_role_binding.connector_rbac
  to   = module.connectors.confluent_role_binding.connector_rbac
}

moved {
  from = terraform_data.guards
  to   = module.connectors.terraform_data.guards
}
