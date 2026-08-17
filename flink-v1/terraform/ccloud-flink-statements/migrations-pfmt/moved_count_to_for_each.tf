# =============================================================================
# PFMT — migración state: count → for_each
# =============================================================================
# La clave de for_each en main.tf es:
#   coalesce(statement-name del YAML, nombre del archivo sin ".yaml")
# Los bloques "to" deben usar ESA misma cadena (en PFMT hoy todos tienen statement-name).
#
# Copiar al raíz del módulo solo para migrar un workspace PFMT; luego puedes borrar la copia del raíz.
#
#   cp migrations-pfmt/moved_count_to_for_each.tf .
#   terraform init && terraform apply
#
# Orden = sort(fileset(".../ddl|dml", "*.yaml")) como en main.tf (PFMT/ccloud-flink-statements).
# Si añades o quitas YAML en PFMT, actualiza estos bloques moved.
# =============================================================================

moved {
  from = confluent_flink_statement.ddl_statements[0]
  to   = confluent_flink_statement.ddl_statements["add-headers-azc-pfmt-client"]
}

moved {
  from = confluent_flink_statement.ddl_statements[1]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-ncif-party-reference-data-directory"]
}

moved {
  from = confluent_flink_statement.ddl_statements[2]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-apsy-account-movements-encrypted"]
}

moved {
  from = confluent_flink_statement.ddl_statements[3]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-apsy-account-batch-movements"]
}

moved {
  from = confluent_flink_statement.ddl_statements[4]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-rcpr-customer-product-and-service"]
}

moved {
  from = confluent_flink_statement.ddl_statements[5]
  to   = confluent_flink_statement.ddl_statements["add-headers-azc-pfmt-product"]
}

moved {
  from = confluent_flink_statement.ddl_statements[6]
  to   = confluent_flink_statement.ddl_statements["add-headers-azc-pfmt-transaction"]
}

moved {
  from = confluent_flink_statement.ddl_statements[7]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-avpl-credit-card-online-operation-encrypted"]
}

moved {
  from = confluent_flink_statement.dml_statements[0]
  to   = confluent_flink_statement.dml_statements["insert-data-to-client"]
}

moved {
  from = confluent_flink_statement.dml_statements[1]
  to   = confluent_flink_statement.dml_statements["insert-data-account-transaction"]
}

moved {
  from = confluent_flink_statement.dml_statements[2]
  to   = confluent_flink_statement.dml_statements["insert-data-product"]
}

moved {
  from = confluent_flink_statement.dml_statements[3]
  to   = confluent_flink_statement.dml_statements["insert-data-card-transaction"]
}
