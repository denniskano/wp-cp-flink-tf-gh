# =============================================================================
# ONE-TIME STATE MIGRATION (PEVE)
# =============================================================================
# Purpose:
# Migrate legacy indexed instances to filename-based for_each keys.
#
# Applies when old state addresses are:
#   confluent_flink_statement.ddl_statements[0..N]
#   confluent_flink_statement.dml_statements[0..N]
#
# New addresses (current implementation):
#   confluent_flink_statement.ddl_statements["<file>.yaml"]
#   confluent_flink_statement.dml_statements["<file>.yaml"]
#
# IMPORTANT:
# - This migration is specific to PEVE file layout.
# - If legacy state uses null_resource.* (older implementation), moved blocks do
#   not apply because resource type changed; use manual rm/import in that case.

moved {
  from = confluent_flink_statement.ddl_statements[0]
  to   = confluent_flink_statement.ddl_statements["01_cc-loc-peve-terraform-input-loop.yaml"]
}

moved {
  from = confluent_flink_statement.ddl_statements[1]
  to   = confluent_flink_statement.ddl_statements["02_cc-loc-peve-terraform-internal.yaml"]
}

moved {
  from = confluent_flink_statement.ddl_statements[2]
  to   = confluent_flink_statement.ddl_statements["03_ddl.yaml"]
}

moved {
  from = confluent_flink_statement.dml_statements[0]
  to   = confluent_flink_statement.dml_statements["01_insert-internal-from-input-loop.yaml"]
}

moved {
  from = confluent_flink_statement.dml_statements[1]
  to   = confluent_flink_statement.dml_statements["02_insert-input-loop-from-internal.yaml"]
}

moved {
  from = confluent_flink_statement.dml_statements[2]
  to   = confluent_flink_statement.dml_statements["03_load-data-input-loop.yaml"]
}

moved {
  from = confluent_flink_statement.dml_statements[3]
  to   = confluent_flink_statement.dml_statements["04_dml.yaml"]
}
