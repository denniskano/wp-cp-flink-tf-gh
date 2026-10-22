# flink-statements

Statements y RBAC por codegen:

- `gen_rbac_flink_dinamic.sh` → `rbac_flink.tf`, `data_sa_flink.tf`
- `gen_stmt_flink_dinamic.sh` → `stmt_flink.tf`, `data_cp_flink.tf` (y data SA extra de los YAML de statement, sin pisar los de rbac)

Los tpl están en `resources/template/`. Esos `.tf` no van al repo.

## `IS_ONLY_DDL`

| Valor | Qué genera |
|---|---|
| omitido / vacío | DDL y DML (local, `tf.sh`) |
| `true` | solo DDL — credenciales `VAR_confluent_flink_api_key` / `_secret`. Sin backend: el marcador `once` no sobrevive al job |
| `false` | DML + marcadores DDL `apply: once` (entran a `tf-flink-stmts.tfstate`) |

El CI de v2 hace **dos pases** (`true` luego `false`). En local no hace falta.

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

`once` no hace falta pasarlo a `ignore` a los 30 días si el marcador ya está en el state de DML. `apply: ignore` si el ALTER ya tiene más de 30 días **y** nunca hubo pase DML (CCloud purgó el job; el primer persist reenviaría el SQL). Un DML streaming con `stopped` tiene que ser `managed`.

## Provider (un solo archivo)

El stack commitea `providers.tf` (backend + cloud key + SR). Terraform no admite otro `terraform {}` al lado.

En el runner, **reemplazar** ese archivo; no crear `provider.tf`:

```bash
# desde stacks/flink-statements
./../../scripts/ci/select-flink-provider.sh a   # DML / apply con state
./../../scripts/ci/select-flink-provider.sh b   # DDL sin backend (IS_ONLY_DDL=true)
```

El GHA de v2 todavía hace `cp … provider.tf` porque su workdir commitea `provider.tf`. Cuando el `-chdir` sea este stack, usa el script de arriba.

`provider-a` = backend Azure. `provider-b` = sin backend. Los dos llevan `cloud_api_key` (data de pool/SA).

State DES: `tf-flink-stm-dev` / `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate`.

`scripts/configure-dns.sh` y `restore-dns.sh` los usa el workflow cuando el runner no resuelve el endpoint de Flink.
