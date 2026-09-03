# Tests

Un directorio por **stack** event-driven, no por verbo (`create`/`delete`) ni por entorno.

| Carpeta | Stack |
|---|---|
| `tests/kafka-connect/` | `stacks/kafka-connect` |
| `tests/flink-compute-pool/` | `stacks/flink-compute-pool` |
| `tests/flink-statements/` | `stacks/flink-statements` |

Los YAML de aquí son **fixtures** (contrato `connects/` + `security/`). No son el repo de resources ni se aplican a Confluent.

```bash
make test          # fixtures + JSON Schema + terraform validate (kafka-connect)
make lint          # terraform fmt -check + JSON Schema (fixtures)
```

JSON Schema (`connects/` / `security/`): [schemas/README.md](../schemas/README.md). Contra resources: `./scripts/ci/schema-lint.sh <connects> <security>`.

Cuando se implemente Flink o SMT: `tests/flink-statements/`, `tests/connect-plugins/`, etc.
