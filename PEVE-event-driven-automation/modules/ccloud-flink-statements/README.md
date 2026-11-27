# ccloud-flink-statements

No hay módulo `for_each`. El HCL lo escriben `gen_stmt_flink_dinamic.sh` y `gen_rbac_flink_dinamic.sh` sobre `stacks/flink-statements`.

YAML (igual que flink-v1):

| Campo | Efecto |
|---|---|
| `properties` | `confluent_flink_statement.properties` (+ catalog/database). Para versionar: `sql.tables.initial-offset-from` |
| `apply: managed` (default) | Resource Terraform |
| `apply: ignore` | No se genera resource. Si estaba managed, el plan propone destroy |
| `apply: once` | `terraform_data` + `scripts/apply-once.sh`. El marcador queda en el state de DML; no se re-crea a los 30 días |

Versionado: YAML nuevo, otro `statement-name`, `initial-offset-from` = name de la que sigue Running. Dos apply (crear la nueva, `stopped: true` en la anterior).
