# ccloud-flink-statements

En v2 el HCL de statements/RBAC se genera en CI:

- `scripts/gen_stmt_flink_dinamic.sh` → `stmt_flink.tf` + `data_cp_flink.tf`
- `scripts/gen_rbac_flink_dinamic.sh` → `rbac_flink.tf` + `data_sa_flink.tf`

Templates: `resources/template/`. Stack: `stacks/flink-statements`.
