# flink-statements

Statements y RBAC por codegen. Los `.tf` no van al repo.

- `gen_rbac_flink_dinamic.sh` → `rbac_flink.tf`, `data_sa_flink.tf`
- `gen_stmt_flink_dinamic.sh` → `stmt_flink.tf`, `data_cp_flink.tf`

Templates en `resources/template/`.

Un apply arma DDL y DML (campo `apply` + `stopped` del YAML). RBAC es otro plan / otro blob.

DDL corre con `SERVICE_ACCOUNT` del Action (`SA_AZC_*_PEVE_FLK_01`): keys y `principal`. El `service-account` del YAML de DDL se ignora. DML usa el SA del YAML.

`stop_statement` en el Action: uno o más `statement-name` DML `managed`, separados por coma. Ese apply los deja `stopped=true` sin tocar el YAML. El siguiente run sin el input usa el `stopped` del YAML. Si el nombre no existe o no es DML managed, el codegen falla.

## `properties` y versionado

En el YAML, no en un `SET` del SQL:

```yaml
properties:
  sql.tables.initial-offset-from: "insert-filtered-passthrough-v2"
  sql.tables.scan.idle-timeout: "30s"
```

Van a `properties` junto con catalog/database. `initial-offset-from` es el `statement-name` de la versión que sigue Running. Dos apply: crear la nueva (`stopped: false`) y después `stopped: true` en la anterior.

`${catalog_name}` y `${cluster_name}` en el SQL se reemplazan igual que en flink-v1.

## `apply`

| Valor | Qué genera |
|---|---|
| omitido / `managed` | `confluent_flink_statement` |
| `ignore` | nada (comentario). Si estaba managed, el plan propone destroy |
| `once` | `terraform_data` + `scripts/apply-once.sh`. No se re-crea si CCloud ya no tiene el job |

`once` vive en el mismo blob que el DML (`tf-flink-stmts.tfstate`). Un DML streaming con `stopped` tiene que ser `managed`.

## Provider

El stack commitea `providers.tf`. Terraform no admite otro `terraform {}` al lado. En el runner se **reemplaza** ese archivo; no se crea `provider.tf`.

```bash
# desde stacks/flink-statements
./../../scripts/ci/select-flink-provider.sh a   # RBAC y statements (backend Azure)
```

`provider-b` era un pase DDL sin state. Ya no se usa.

State DES: container `tf-flink-stm-dev`. Dos keys por pipeline: `tf-flink-rbacs.tfstate` y `tf-flink-stmts.tfstate`.

Si el runner no resuelve el endpoint de Flink, el workflow usa `configure-dns.sh` / `restore-dns.sh`.
