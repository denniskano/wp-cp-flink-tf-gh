# PEVE-kafka-connect-resources-v1

YAML de Kafka Connect (conectores + RBAC del SA). Terraform y workflows no van acá.

## Lint local

Desde la raíz de este repo:

```bash
pip install check-jsonschema
make lint                              # todo el repo
make lint UC=PEVE                      # solo tu app
make lint UC=PEVE/desa                 # un ambiente
make lint UC=PEVE/desa/use-case-name-02
```

Los schema están en `schemas/`. No hace falta clonar automation.

En VS Code / Cursor: abrir **esta carpeta** como workspace e instalar la extensión que recomienda el repo (`redhat.vscode-yaml`). Los `connects/*.yaml` y `security/*.yaml` se validan al tipear (subrayado + hover). Terminal → Run Task → `lint: carpeta` si querés el `make lint` de una app.

El job `deploy-kafka-connect` corre el mismo `scripts/lint.sh` (no corre en `destroy`).

## Repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** | Terraform (`stacks/kafka-connect`) |
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

Si cambia el módulo, actualizar `schemas/*.json` en este repo.

## Ejemplo

`PEVE/desa/use-case-name-02/` — Datagen → `azc-peve-transaction` → Postgres sink.
