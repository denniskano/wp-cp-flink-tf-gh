# ccloud-flink-compute-pool

En v2 el HCL de pools **no** es un módulo reutilizable: `scripts/gen_cp_flink_dinamic.sh` escribe `cp_flink.tf` dentro del stack (`stacks/flink-compute-pool`).

No hay `fileset`/`yamldecode` aquí.
