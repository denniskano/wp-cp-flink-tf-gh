# Stack: flink-statements

Raíz Terraform. Statements + RBAC se generan con codegen (mismo modelo que v2):

- `scripts/gen_rbac_flink_dinamic.sh` → `rbac_flink.tf` + `data_sa_flink.tf`
- `scripts/gen_stmt_flink_dinamic.sh` → `stmt_flink.tf` + `data_cp_flink.tf`

Templates originales: `resources/template/{rbac,stmt,data_sa,data_cp}_flink.tf.tpl`. Esos `.tf` no se versionan.

State DES: `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate` (container `tf-flink-stm-dev`).
