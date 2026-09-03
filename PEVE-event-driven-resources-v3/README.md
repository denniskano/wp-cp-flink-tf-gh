# PEVE-event-driven-resources-v3

YAML del **core EDA**: topics, Schema Registry, RBAC de cluster y SA del use-case.

No hay Terraform ni workflows aquí.

## Cinco repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** | Terraform codegen (`stacks/eda-core` + `generate_*_dinamic.sh`) |
| **PEVE-event-driven-resources-v2** | Workflow `peve-resources-desa.yml` (DES) |
| **PEVE-kafka-connect-resources-v1** | YAML Connect (asume que este core ya existe) |
| **PEVE-stream-processing-resources-v2** | YAML Flink (asume que este core ya existe) |
| **PEVE-event-driven-resources-v3** (este) | YAML core |

El workflow clona este repo a `./externo`. Aplicar `eda-core` antes que Connect o Flink statements.

## Layout (contrato del codegen)

```
{CODAPP}/
  desa|cert|prod/
    topics/cc-*-topics.yaml
    security/cc-*-rbac-{des|cer|pro}.yaml
    governance/sr-*-subjects.yaml
    asyncapi/                 # Avro/JSON referenciados por governance
```

Ejemplo DES (`PEVE/`): `topics/cc-azure_eu2_kafka01-topics.yaml`, `security/cc-azure_eu2_kafka01-rbac-des.yaml`, `governance/sr-cc-subjects.yaml`, `asyncapi/azc-peve-transaction-value-v1.avsc`.

`{CODAPP}/desa/{use-case}/topics/{nombre}.yaml` **no** lo leen los `generate_*`.

## Validación

Aún no hay JSON Schema en automation para este contrato. El workflow sale 0 si no hay YAML que matchee el glob.
