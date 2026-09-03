# JSON Schema de Connect

Draft-07 para `connects/` y `security/` de `PEVE-kafka-connect-resources-v1`.

```bash
make lint-yaml

./scripts/ci/schema-lint.sh \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/connects \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/security
```

Usa `check-jsonschema` si está instalado; si no, Ajv (`node scripts/ci/ajv-lint.mjs`).

| Archivo | Aplica a |
|---|---|
| connects.schema.json | `connects/*.yaml` |
| security.schema.json | `security/*.yaml` |

`make lint` / `make test` lo corren contra las fixtures. El workflow `deploy-kafka-connect` lo corre sobre `./externo` antes de Terraform, excepto en destroy.

Flink y eda-core no tienen schema todavía. `validate-yaml.sh` solo mira que existan carpetas y `*.yaml`. Los guards de Terraform evitan un apply vacío. El plan es el que habla con Confluent.

Un typo tipo `resource_type: grup` puede pasar el plan (Terraform lo ignora) y lo pesca el schema.
