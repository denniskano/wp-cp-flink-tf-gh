module "connectors" {
  source = "../../modules/ccloud-connectors"

  environment_id             = var.environment_id
  kafka_cluster_id           = var.kafka_cluster_id
  connectors_dir             = var.connectors_dir
  security_dir               = var.security_dir
  environment                = var.environment
  connector_secrets          = var.connector_secrets
  connector_status_overrides = var.connector_status_overrides
  allow_empty_connectors     = var.allow_empty_connectors
}
