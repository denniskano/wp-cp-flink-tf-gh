# State

Backend Azure RM. El workflow manda `storage_account_name`, `container_name` y `key` en el `init`.

| Stack | Container | Key |
|---|---|---|
| kafka-connect | tf-connect-dev / -cert / -prod | `{env}/{CODAPP}/{use_case}/tf-connect.tfstate` |
| connect-plugins | tf-connect-dev | `dev/{CODAPP}/connect-plugins/tf-connect-plugins.tfstate` |
| flink-compute-pool | tf-flink-cps-dev | `dev/{CODAPP}/ccloud-flink/compute-pool/tf-flink-cps.tfstate` |
| flink-statements | tf-flink-stm-dev / -cert / -prod | `{env}/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs.tfstate` (RBAC) y `…/tf-flink-stmts.tfstate` (DDL+DML) |
| eda-core | tf-peve-resources | `{DESA}/{CODAPP}/{cc\|cfk}/tf-{properties_name}.tfstate` (topics). RBAC y SR agregan `-rbac` / `-schemaregistry`. Lo arma `scripts/terraform_task.sh`. |

Si más adelante se llenan los otros stacks, key **nueva**. No reutilizar `tf-connect.tfstate`, `tf-connect-plugins.tfstate` ni las de Flink.

El blob viejo `tf-flink-rbacs-stmts.tfstate` ya no se usa: se partió en rbac + stmts.
