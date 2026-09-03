# Contrato entre los cinco repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** (este) | Terraform (módulos/stacks), scripts, tests, JSON Schema de Connect |
| **PEVE-event-driven-resources-v2** | GitHub Actions. Clona este repo → `./iac` y el YAML del stack → `./externo` |
| **PEVE-kafka-connect-resources-v1** | YAML Connect: `{CODAPP}/{desa\|cert\|prod}/{use-case}/connects` + `security` |
| **PEVE-stream-processing-resources-v2** | YAML Flink: `{CODAPP}/ccloud-flink/{env}/compute-pool` + `{pipeline}/statement` |
| **PEVE-event-driven-resources-v3** | YAML core: topics, schemas, RBAC/SA del use-case (`stacks/eda-core`) |

Los workflows **no** viven aquí. En cada run:

1. Checkout de este repo en `./iac` (`IAC_REF` = tag o rama).
2. Checkout del YAML del stack en `./externo`.
3. Validación de existencia (`validate-yaml.sh` o `validate-flink-yaml.sh`).
4. Connect: **JSON Schema** (`schema-lint.sh`). Flink: codegen `gen_*_dinamic.sh` (sin schema). No corre schema en `destroy`.
5. Vault + (Flink: generate `*_flink.tf`) + `terraform -chdir=./iac/stacks/<stack>`.

eda-core sigue siendo esqueleto.

| Stack | `./externo` viene de |
|---|---|
| `kafka-connect` | PEVE-kafka-connect-resources-v1 |
| `flink-compute-pool`, `flink-statements` | PEVE-stream-processing-resources-v2 |
| `eda-core` | PEVE-event-driven-resources-v3 |

No hay YAML de aplicación en este repositorio. Los JAR/ZIP (UDF Flink, SMT) tampoco: el workflow los baja y pasa `artifact_file`.

Detalle del schema: [../schemas/README.md](../schemas/README.md). Manual: [DEVELOPER.md](DEVELOPER.md).
