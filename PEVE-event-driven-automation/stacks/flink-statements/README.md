# flink-statements

Statements y RBAC por codegen, igual que en v2:

- `gen_rbac_flink_dinamic.sh` → `rbac_flink.tf`, `data_sa_flink.tf`
- `gen_stmt_flink_dinamic.sh` → `stmt_flink.tf`, `data_cp_flink.tf`

Los tpl están en `resources/template/`. Esos `.tf` no van al repo.

State DES: `tf-flink-stm-dev` / `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate`.

`scripts/configure-dns.sh` y `restore-dns.sh` los usa el workflow cuando el runner no resuelve el endpoint de Flink (Google/Cloudflare temporal; después se vuelve al resolv original).
