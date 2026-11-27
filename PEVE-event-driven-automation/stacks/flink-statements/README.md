# flink-statements

Statements y RBAC por codegen:

- `gen_rbac_flink_dinamic.sh` → `rbac_flink.tf`, `data_sa_flink.tf`
- `gen_stmt_flink_dinamic.sh` → `stmt_flink.tf`, `data_cp_flink.tf` (y data SA extra de los YAML de statement, sin pisar los de rbac)

Los tpl están en `resources/template/`. Esos `.tf` no van al repo.

Un apply genera **DDL y DML** (ciclo v1: `apply` + `stopped`). RBAC va en un plan aparte (otro blob). El GHA no tiene `IS_ONLY_DDL`. Input opcional `stop_statement`: `statement-name` de un DML managed → ese apply lo deja `stopped=true` (el YAML no se reescribe; el próximo run sin el input usa el `stopped` del YAML).

## `properties` y versionado

En el YAML (no `SET` en el SQL):

```yaml
properties:
  sql.tables.initial-offset-from: "insert-filtered-passthrough-v2"
  sql.tables.scan.idle-timeout: "30s"
```

El codegen las mete en `properties` junto a `sql.current-catalog` / `sql.current-database`. El valor de `initial-offset-from` es el **statement-name** de la versión Running. Dos apply: crear la nueva (`stopped: false`), después `stopped: true` solo en la anterior.

`${catalog_name}` y `${cluster_name}` en el SQL se reemplazan como en flink-v1.

## `apply` (ciclo de vida)

| Valor | HCL generado |
|---|---|
| omitido / `managed` | `confluent_flink_statement` |
| `ignore` | nada (comentario). Plan: destroy si estaba managed |
| `once` | `terraform_data` + `scripts/apply-once.sh` (REST). No se re-crea si CCloud purgó el job |

`once` queda en el mismo blob que el DML (`tf-flink-stmts.tfstate`); no hace falta pasarlo a `ignore` a los 30 días. Un DML streaming con `stopped` tiene que ser `managed`.

## Provider (un solo archivo)

El stack commitea `providers.tf` (backend + cloud key + SR). Terraform no admite otro `terraform {}` al lado.

En el runner, **reemplazar** ese archivo; no crear `provider.tf`:

```bash
# desde stacks/flink-statements
./../../scripts/ci/select-flink-provider.sh a   # RBAC y statements (backend Azure)
```

`provider-a` = backend Azure. `provider-b` quedó de un pase DDL sin state; el GHA ya no lo usa.

State DES: `tf-flink-stm-dev` / `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate`.

`scripts/configure-dns.sh` y `restore-dns.sh` los usa el workflow cuando el runner no resuelve el endpoint de Flink.
