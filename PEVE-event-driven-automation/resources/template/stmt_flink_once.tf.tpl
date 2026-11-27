#INI ONCE: once_${STATEMENT_NAME}
# apply: once — se crea una vez (API). El marcador queda en el state.
# CCloud puede borrar el job a los 30 días; Terraform no lo vuelve a crear.
# ignore_changes: cambiar el SQL no re-dispara. Para repetir, cambia statement-name.
resource "terraform_data" "once_${STATEMENT_NAME}" {
  input = {
    name       = "${STATEMENT_NAME}"
    statement  = <<-SQL
${STATEMENT}
SQL
    pool_id    = data.confluent_flink_compute_pool.cp_${COMPUTE_POOL}.id
    rest       = var.flink_private_rest_endpoint
    org_id     = "${ORGANIZATION_ID}"
    env_id     = "${ENVIRONMENT_ID}"
    principal  = data.confluent_service_account.sa_${PRINCIPAL}.id
    stopped    = "${STOPPED}"
    properties = jsonencode({
${PROPERTIES_BLOCK}
    })
  }

  provisioner "local-exec" {
    when    = create
    command = "bash ./scripts/apply-once.sh"
    environment = {
      ONCE_ACTION                = "create"
      ONCE_NAME                  = self.input.name
      ONCE_SQL                   = self.input.statement
      ONCE_POOL_ID               = self.input.pool_id
      ONCE_REST_ENDPOINT         = self.input.rest
      ONCE_ORG_ID                = self.input.org_id
      ONCE_ENV_ID                = self.input.env_id
      ONCE_PRINCIPAL             = self.input.principal
      ONCE_STOPPED               = self.input.stopped
      ONCE_PROPERTIES            = self.input.properties
      CONFLUENT_FLINK_API_KEY    = "${ONCE_API_KEY}"
      CONFLUENT_FLINK_API_SECRET = "${ONCE_API_SECRET}"
    }
  }

  lifecycle {
    ignore_changes = [input]
  }

  depends_on = [
    ${DEPENDS_ON_BLOCK}
  ]
}
#FIN ONCE
