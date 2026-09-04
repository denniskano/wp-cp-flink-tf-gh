# State

Backend Azure RM. El workflow envía `storage_account_name`, `container_name` y `key` en el `init`.

Lo que está en uso (DES):

| Stack | Container | Key |
|---|---|---|
| kafka-connect | tf-connect-dev | `dev/{CODAPP}/{use_case}/tf-connect.tfstate` |
| flink-compute-pool | tf-flink-cps-dev | `dev/{CODAPP}/ccloud-flink/compute-pool/tf-flink-cps.tfstate` |
| flink-statements | tf-flink-stm-dev | `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate` |
| eda-core | tf-peve-resources | `{DESA}/{CODAPP}/{cc\|cfk}/tf-{properties_name}.tfstate` (topics). RBAC y SR agregan `-rbac` / `-schemaregistry` al nombre. Lo arma `scripts/terraform_task.sh`. |

Si más adelante se llenan los otros stacks, hay que inventar key nueva. No reutilizar `tf-connect.tfstate` ni las de Flink.

cert/prod todavía no están cableados en v2. Cuando existan, cambia el container / el prefijo; no el layout de este repo.
