# =============================================================================
# BADI — migración state: count → for_each
# =============================================================================
# La clave de for_each en main.tf es:
#   coalesce(statement-name del YAML, nombre del archivo sin ".yaml")
# Los bloques "to" deben usar ESA misma cadena (en BADI hoy todos tienen statement-name).
#
# Copiar al raíz del módulo solo para migrar un workspace BADI; luego puedes borrar la copia del raíz.
#
#   cp migrations-badi/moved_count_to_for_each.tf .
#   terraform init && terraform apply
#
# Orden = sort(fileset(".../ddl|dml", "*.yaml")) como en main.tf (BADI/ccloud-flink-statements).
# Si añades o quitas YAML en BADI, actualiza estos bloques moved.
# =============================================================================

moved {
  from = confluent_flink_statement.ddl_statements[0]
  to   = confluent_flink_statement.ddl_statements["azc-badi-event-history"]
}

moved {
  from = confluent_flink_statement.ddl_statements[1]
  to   = confluent_flink_statement.ddl_statements["azc-badi-non-monetary-fraud-events"]
}

moved {
  from = confluent_flink_statement.ddl_statements[2]
  to   = confluent_flink_statement.ddl_statements["azc-badi-event-history-01"]
}

moved {
  from = confluent_flink_statement.ddl_statements[3]
  to   = confluent_flink_statement.ddl_statements["add-virtual-headers-azc-badi-event-history"]
}

moved {
  from = confluent_flink_statement.ddl_statements[4]
  to   = confluent_flink_statement.ddl_statements["add-headers-azc-bsns-event-history"]
}

moved {
  from = confluent_flink_statement.dml_statements[0]
  to   = confluent_flink_statement.dml_statements["insert-data-non-monetary-fraud-events"]
}
