# JSON Schema — YAML de Connect (resources)

Contrato de `connects/` y `security/` en **PEVE-kafka-connect-resources-v1** (JSON Schema Draft-07).

El workflow `deploy-kafka-connect` en **PEVE-event-driven-resources-v2** y `make lint-yaml` validan con:

1. **check-jsonschema** (preferido, `pip install check-jsonschema`)
2. **Ajv** (`node scripts/ci/ajv-lint.mjs`) si no hay check-jsonschema

```bash
# Desde PEVE-event-driven-automation
make lint-yaml

./scripts/ci/schema-lint.sh \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/connects \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/security
```

| Schema | Archivos |
|---|---|
| `schemas/connects.schema.json` | `connects/*.yaml` |
| `schemas/security.schema.json` | `security/*.yaml` |

## Cuándo corre

| Momento | Qué hace |
|---|---|
| `make lint` / `make test` (este repo) | Fixtures + YAML inválidos a propósito |
| `deploy-kafka-connect` **antes** de Terraform, si `action` ≠ `destroy` | Lint de `./externo/.../connects` y `security` |
| `destroy` | Se omite (puede no haber YAML) |
| Flink / eda-core | Aún no hay schema |

## Qué valida vs qué no

| Capa | Valida |
|---|---|
| `validate-yaml.sh` | Existen carpetas y `*.yaml` |
| JSON Schema | Forma: `SERVICE_ACCOUNT`, `topics` xor `kafka.topic`, `vault.secrets.path`+`field`, `resource_type` ∈ topic/subject/group/transactional-id, sin `config_sensitive` en resources |
| Guards Terraform | Apply vacío / `security_dir` |
| `terraform plan` | State + Confluent (SA existe, drift) |

Un `resource_type: grup` pasa el plan (Terraform lo descarta) y **falla el schema**.
