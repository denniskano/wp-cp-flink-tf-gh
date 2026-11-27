#INI STMT: statement_${STATEMENT_NAME}
resource "confluent_flink_statement" "statement_${STATEMENT_NAME}" {
  statement_name = "${STATEMENT_NAME}"
  organization { id = "${ORGANIZATION_ID}" }
  environment  { id = "${ENVIRONMENT_ID}" }
  compute_pool { id = data.confluent_flink_compute_pool.cp_${COMPUTE_POOL}.id }
  principal    { id = data.confluent_service_account.sa_${PRINCIPAL}.id }
  credentials {
    ${VAR_FLINK_APIKEY}
    ${VAR_FLINK_APISECRET}
  }
  rest_endpoint = var.flink_private_rest_endpoint

  properties = {
${PROPERTIES_BLOCK}
  }
  stopped   = try(tobool("${STOPPED}"), false)
  statement = <<-SQL
${STATEMENT}
SQL

  depends_on = [
    ${DEPENDS_ON_BLOCK}
  ]
}
#FIN STMT
