#INI STMT: statement_${STATEMENT_NAME}
resource "confluent_flink_statement" "statement_${STATEMENT_NAME}" {
  statement_name = "${STATEMENT_NAME}"
  #provider = confluent
  organization { id = "${ORGANIZATION_ID}" }
  environment  { id = "${ENVIRONMENT_ID}" }
  compute_pool { id = data.confluent_flink_compute_pool.cp_${COMPUTE_POOL}.id }
  principal    { id = data.confluent_service_account.sa_${PRINCIPAL}.id }
  credentials {
    key    = "${APIKEY_KEY}"
    secret = "${APIKEY_SECRET}"
  }
  #rest_endpoint = local.compute_pools_map[${configurations_rest_endpoint}].private_rest_endpoint
  #rest_endpoint = "${REST_ENDPOINT}"
  rest_endpoint = try(var.flink_private_rest_endpoint, data.confluent_flink_region.data_flink_region.rest_endpoint)
  #rest_endpoint = data.confluent_flink_region.data_flink_region.private_rest_endpoint
  
  properties         = {
    "sql.current-catalog"  = "${CATALOG_NAME}"
    "sql.current-database" = "${CLUSTER_NAME}"
    }
  stopped         = try(tobool("${STOPPED}"),false)
  statement = <<-SQL
${STATEMENT}
SQL

  depends_on = [
    ${DEPENDS_ON_BLOCK}
  ]
}
#FIN STMT
