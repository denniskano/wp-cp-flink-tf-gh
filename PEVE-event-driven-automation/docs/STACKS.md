# Stacks

Un **stack** es una raíz Terraform con backend. Un **módulo** no se aplica solo.

| Stack | Módulo | Unidad de deploy | Workflow (otro repo) |
|---|---|---|---|
| `kafka-connect` | `ccloud-connectors` | use-case (`connects/` + `security/`) | deploy-kafka-connect |
| `connect-plugins` | `ccloud-connect-smt` | environment (JAR/ZIP de SMT) | deploy-connect-plugins |
| `flink-compute-pool` | `ccloud-flink-compute-pool` | CODAPP (esqueleto) | deploy-compute-pools |
| `flink-artifacts` | `ccloud-flink-artifacts` | CODAPP (UDF JAR/Python) | deploy-flink-artifacts |
| `flink-connections` | `ccloud-flink-connection` | CODAPP / env (OpenAI, Azure ML, …) | deploy-flink-connections |
| `flink-statements` | `ccloud-flink-statements` | pipeline (esqueleto) | deploy-flink-statements |
| `eda-core` | topics / schemas / rbac / SA del use-case | use-case (esqueleto) | deploy-eda-core |
| `tableflow` | `ccloud-tableflow` | use-case / topic | deploy-tableflow |
| `ksql` | `ccloud-ksql` | use-case (esqueleto) | deploy-ksql |

Orden cuando hay dependencias:

1. `eda-core` (topic, schema, RBAC, SA)
2. `connect-plugins` / `flink-artifacts` / `flink-connections` / `flink-compute-pool` (plataforma)
3. `kafka-connect` / `flink-statements` / `tableflow`

No combinar stacks en un solo `apply`. Service accounts y API keys del use-case van en **`eda-core`**, no en un stack `identity`.

