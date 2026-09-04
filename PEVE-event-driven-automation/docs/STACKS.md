# Stacks

Cada carpeta en `stacks/` es una raíz Terraform (backend Azure). No se aplican dos stacks en el mismo `apply`.

| Stack | Cómo se arma el HCL | Unidad | YAML | Workflow DES |
|---|---|---|---|---|
| kafka-connect | módulo `ccloud-connectors` | use-case | kafka-connect-resources-v1 | deploy-kafka-connect |
| flink-compute-pool | `gen_cp_flink_dinamic.sh` | CODAPP | stream-processing-resources-v2 | deploy-compute-pools-desa-2-0 |
| flink-statements | `gen_rbac` + `gen_stmt` | pipeline | stream-processing-resources-v2 | deploy-flink-statements-desa-2-0 |
| eda-core | `generate_topic` / `schema_registry` / `rbac` + `terraform_task.sh` | CODAPP + env | event-driven-resources-v3 | peve-resources-desa |
| connect-plugins | pendiente (`ccloud-connect-smt`) | environment | — (JAR) | — |
| flink-artifacts | pendiente | CODAPP | — (JAR) | — |
| flink-connections | pendiente | CODAPP / env | — | — |
| tableflow | pendiente | use-case | v3 | — |
| ksql | pendiente | use-case | v3 | — |

Si hay dependencias: primero eda-core (topic, schema, SA), después pools / artifacts / connections / SMT, después Connect o statements.

Los SA y API keys del use-case salen de eda-core, no de un stack aparte.

Connect: existencia acá (`validate-yaml.sh`). Flink solo chequea que existan archivos (`scripts/ci/validate-flink-yaml.sh`).
