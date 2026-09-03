# PEVE-kafka-connect-resources-v1

YAML de **Kafka Connect** full-managed (conectores + RBAC del SA del conector).

No hay Terraform ni workflows aquí.

## Cinco repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** | Terraform (`stacks/kafka-connect`) + JSON Schema de este YAML |
| **PEVE-event-driven-resources-v2** | Workflow `deploy-kafka-connect.yml` (clona este repo a `./externo`) |
| **PEVE-kafka-connect-resources-v1** (este) | YAML Connect |
| **PEVE-stream-processing-resources-v2** | YAML Flink (otro contrato) |
| **PEVE-event-driven-resources-v3** | Topics, schemas, SA del use-case (deben existir **antes** del conector) |

## Layout

```
{CODAPP}/
  desa|cert|prod/
    {use-case}/
      connects/*.yaml
      security/*.yaml
```

Solo `*.yaml` (no `*.yml`, no subcarpetas). El input `use_case` del workflow es el nombre de la carpeta.

## Contrato (lo que Terraform y el schema esperan)

- Clave de `for_each` = **nombre del archivo sin `.yaml`**. Renombrar el archivo o cambiar `name` recrea el conector (se pierden offsets).
- `kafka.auth.mode`: `SERVICE_ACCOUNT`. El SA se busca por `vault.service_account` (`display_name`).
- Secretos: `vault.secrets` con `path` + `field` por cada clave. No poner `config_sensitive` en el YAML.
- Topics: `topics` **o** `kafka.topic`, no ambos.
- `security/`: `resource_type` ∈ `topic` | `subject` | `group` | `transactional-id`. Sink: consumer group PREFIXED `connect-lcc-`.
- `status` del YAML es el de apply. Pause del workflow es temporal; el siguiente apply restaura el YAML.

JSON Schema (forma) y `validate-yaml.sh` (existencia) viven en **PEVE-event-driven-automation**. El workflow los corre **antes** de Terraform, excepto en `destroy`.

```bash
# Desde el clone de PEVE-event-driven-automation (hermano de este repo)
./scripts/ci/schema-lint.sh \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/connects \
  ../PEVE-kafka-connect-resources-v1/PEVE/desa/use-case-name-02/security
```

Flink y eda-core **no** usan estos schemas.

## Ejemplo

`PEVE/desa/use-case-name-02/` — Datagen → `azc-peve-transaction` → Postgres sink.
