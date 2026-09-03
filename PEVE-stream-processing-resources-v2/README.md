# PEVE-stream-processing-resources-v2

YAML de **Flink**: compute pools y statements (DDL/DML + RBAC del SA de ejecución).

Contenido copiado desde `flink-v2/PEVE-stream-processing-resources-v1` (`PEVE/`, `APPV-PARTNER/`, `PEVE-PARTNER/`).

No hay Terraform ni workflows aquí.

## Cinco repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** | Terraform (`stacks/flink-compute-pool`, `stacks/flink-statements`) |
| **PEVE-event-driven-resources-v2** | Workflows `deploy-flink-compute-pools.yml` y `deploy-flink-statements.yml` |
| **PEVE-kafka-connect-resources-v1** | YAML Connect (otro contrato) |
| **PEVE-stream-processing-resources-v2** (este) | YAML Flink |
| **PEVE-event-driven-resources-v3** | Topics, schemas, SA del dominio (aplicar **antes** de statements) |

El workflow clona este repo a `./externo` y genera el HCL con `gen_*_dinamic.sh` (codegen), no con `fileset` en Terraform.

## Layout

```
{CODAPP}/
  ccloud-flink/
    desa|cert|prod/
      compute-pool/cc-compute-pools.yaml
      {pipeline}/
        security/
        statement/ddl/*.yaml
        statement/dml/*.yaml
```

## Contrato

**Pools:** `compute_pools[].{cloud,region,max_cfu,pool_name}`. Key Terraform = `pool_name`.

**Statements:** `statement-name`, `flink-compute-pool` (display_name del pool), `service-account`, `api-key`, `statement` (SQL). `stopped` opcional. Key Terraform = `statement-name` (si falta, filename).

**Security:** mismo shape que Connect (`cluster.cc.rbac`) más `resource_type: compute-pool` (`FlinkDeveloper`).

El workflow baja `api-key`/`service-account` de Vault a `flink_credentials["{SA}/{AK}"]`. No poner secretos en el YAML.

## Validación

`validate-flink-yaml.sh` (existencia) corre en GHA **antes** de Terraform. Aún **no** hay JSON Schema para Flink; el de Connect no aplica aquí.
