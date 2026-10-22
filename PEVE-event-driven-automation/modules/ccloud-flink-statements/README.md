# ccloud-flink-statements

No hay módulo `for_each`. El HCL lo escribe `gen_stmt_flink_dinamic.sh` + `gen_rbac_flink_dinamic.sh` sobre `stacks/flink-statements`.

Contrato del YAML (mismo que flink-v1):

| Campo | Efecto |
|---|---|
| `properties` | Va a `confluent_flink_statement.properties` (más catalog/database). Carry-over: `sql.tables.initial-offset-from` |
| `apply: managed` (default) | Resource Terraform; se crea/actualiza/destruye |
| `apply: ignore` | No se genera resource. Si estaba managed, el plan propone destroy del job |
| `apply: once` | `terraform_data` + `scripts/apply-once.sh`. El pase DML también emite el marcador (state remoto); no se re-crea a los 30 días |

Versionado: YAML nuevo, otro `statement-name`, `properties.sql.tables.initial-offset-from` = name de la versión Running. Dos apply (crear nueva, luego `stopped: true` en la anterior).
