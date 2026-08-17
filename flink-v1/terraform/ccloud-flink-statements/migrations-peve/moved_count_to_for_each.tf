# =============================================================================
# PEVE — migración state: count → for_each
# =============================================================================
# La clave de for_each en main.tf es:
#   coalesce(statement-name del YAML, nombre del archivo sin ".yaml")
# Los bloques "to" deben usar ESA misma cadena (en PEVE hoy todos tienen statement-name).
#
# Copiar al raíz del módulo solo para migrar; luego puedes borrar esta copia del raíz.
#
#   cp migrations-peve/moved_count_to_for_each.tf .
#   terraform init && terraform apply
#
# Orden = sort(fileset(".../ddl|dml", "*.yaml")) como en main.tf.
# Si añades o quitas YAML en PEVE, actualiza estos bloques moved.
# =============================================================================

moved {
  from = confluent_flink_statement.ddl_statements[0]
  to   = confluent_flink_statement.ddl_statements["create-azc-peve-terraform-input-loop"]
}

moved {
  from = confluent_flink_statement.ddl_statements[1]
  to   = confluent_flink_statement.ddl_statements["create-azc-peve-terraform-internal"]
}

moved {
  from = confluent_flink_statement.ddl_statements[2]
  to   = confluent_flink_statement.ddl_statements["create-demo-table"]
}

moved {
  from = confluent_flink_statement.dml_statements[0]
  to   = confluent_flink_statement.dml_statements["load-data-input-loop-v2"]
}

moved {
  from = confluent_flink_statement.dml_statements[1]
  to   = confluent_flink_statement.dml_statements["insert-internal-from-input-loop-v1"]
}

moved {
  from = confluent_flink_statement.dml_statements[2]
  to   = confluent_flink_statement.dml_statements["insert-input-loop-from-internal-v1"]
}

moved {
  from = confluent_flink_statement.dml_statements[3]
  to   = confluent_flink_statement.dml_statements["load-data-input-loop-v3"]
}

moved {
  from = confluent_flink_statement.dml_statements[4]
  to   = confluent_flink_statement.dml_statements["insert-internal-from-input-loop-v2"]
}

moved {
  from = confluent_flink_statement.dml_statements[5]
  to   = confluent_flink_statement.dml_statements["load-data-input-loop-v2-99"]
}
