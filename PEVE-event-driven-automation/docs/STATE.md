# Terraform state

Backend: Azure RM. El workflow pasa `-backend-config`.

| Stack | Key (DES / `dev`) |
|---|---|
| kafka-connect | `dev/{CODAPP}/{use_case}/tf-connect.tfstate` |
| connect-plugins | `dev/{CODAPP}/tf-connect-plugins.tfstate` (propuesto) |
| flink-compute-pool | `dev/{CODAPP}/tf-flink.tfstate` (hoy; alinear al migrar) |
| flink-artifacts | `dev/{CODAPP}/tf-flink-artifacts.tfstate` (propuesto) |
| flink-connections | `dev/{CODAPP}/tf-flink-connections.tfstate` (propuesto) |
| flink-statements | `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate` |
| eda-core | `dev/{CODAPP}/{use_case}/tf-eda.tfstate` (propuesto) |
| tableflow | `dev/{CODAPP}/{use_case}/tf-tableflow.tfstate` (propuesto) |
| ksql | `dev/{CODAPP}/{use_case}/tf-ksql.tfstate` (propuesto) |

`cert` / `prod` sustituyen el prefijo `dev` cuando existan esos workflows.

Container actual de Connect: `tf-connect-dev`. No reutilizar el state de Flink.
