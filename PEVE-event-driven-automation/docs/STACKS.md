# Stacks

Un **stack** es una raíz Terraform con backend. Un **módulo** no se aplica solo.

| Stack | Módulo | Unidad de deploy | Resources (`./externo`) | Workflow (`PEVE-event-driven-resources-v2`) |
|---|---|---|---|---|
| `kafka-connect` | `ccloud-connectors` | use-case (`connects/` + `security/`) | PEVE-kafka-connect-resources-v1 | deploy-kafka-connect |
| `connect-plugins` | `ccloud-connect-smt` | environment (JAR/ZIP de SMT) | (binario, no este YAML) | deploy-connect-plugins |
| `flink-compute-pool` | codegen `gen_cp_flink_dinamic.sh` | CODAPP (`compute-pool/`) | PEVE-stream-processing-resources-v2 | deploy-flink-compute-pools |
| `flink-artifacts` | `ccloud-flink-artifacts` | CODAPP (UDF JAR/Python) | (binario) | deploy-flink-artifacts |
| `flink-connections` | `ccloud-flink-connection` | CODAPP / env | — | deploy-flink-connections |
| `flink-statements` | codegen `gen_rbac` + `gen_stmt` | pipeline (`statement/` + `security/`) | PEVE-stream-processing-resources-v2 | deploy-flink-statements |
| `eda-core` | codegen `generate_{topic,schema_registry,rbac}_dinamic.sh` | CODAPP + env (`topics/` + `governance/` + `security/`) | PEVE-event-driven-resources-v3 | peve-resources-desa |
| `tableflow` | `ccloud-tableflow` | use-case / topic | PEVE-event-driven-resources-v3 | deploy-tableflow |
| `ksql` | `ccloud-ksql` | use-case (esqueleto) | PEVE-event-driven-resources-v3 | deploy-ksql |

Orden cuando hay dependencias:

1. `eda-core` (topic, schema, RBAC, SA)
2. `connect-plugins` / `flink-artifacts` / `flink-connections` / `flink-compute-pool` (plataforma)
3. `kafka-connect` / `flink-statements` / `tableflow`

No combinar stacks en un solo `apply`. Service accounts y API keys del use-case van en **`eda-core`**, no en un stack `identity`.

Validación Connect (JSON Schema): [../schemas/README.md](../schemas/README.md). Flink: `scripts/ci/validate-flink-yaml.sh` (existencia; sin schema todavía). Workflows: **PEVE-event-driven-resources-v2**.


