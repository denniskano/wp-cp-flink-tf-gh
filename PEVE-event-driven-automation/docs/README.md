# Repos

| Repo | Qué hay |
|---|---|
| PEVE-event-driven-automation (este) | Terraform, scripts |
| PEVE-event-driven-resources-v2 | GitHub Actions |
| PEVE-kafka-connect-resources-v1 | YAML Connect `{CODAPP}/{env}/{use-case}/connects` + `security` |
| PEVE-stream-processing-resources-v2 | YAML Flink `{CODAPP}/ccloud-flink/{env}/…` |
| PEVE-event-driven-resources-v3 | topics, schemas, RBAC/SA |

Cada job de v2 hace más o menos lo mismo:

1. Checkout de este repo → `./iac` (el pin es `IAC_REF`).
2. Checkout del YAML → `./externo`.
3. Validar que existan los yaml. En Connect el schema lo corre `./externo/scripts/lint.sh` (repo v1); en destroy no.
4. Flink y eda-core generan el `.tf` en el runner (`gen_*` / `generate_*`). Connect no: lee el YAML directo.
5. Vault y `terraform -chdir=./iac/stacks/<stack>`. eda-core es distinto: arma `./automation` y llama `terraform_task.sh`.

| Stack | YAML en |
|---|---|
| kafka-connect | PEVE-kafka-connect-resources-v1 |
| flink-compute-pool, flink-statements | PEVE-stream-processing-resources-v2 |
| eda-core | PEVE-event-driven-resources-v3 |

Los JAR (SMT / UDF) no se versionan acá. El workflow los baja y pasa la ruta.

Ver [DEVELOPER.md](DEVELOPER.md). El lint del YAML Connect está en PEVE-kafka-connect-resources-v1.
