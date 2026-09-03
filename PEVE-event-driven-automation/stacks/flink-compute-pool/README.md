# flink-compute-pool

`gen_cp_flink_dinamic.sh` escribe `cp_flink.tf` (no se commitea) usando `resources/template/cp_flink.tf.tpl`.

```bash
export ENVIRONMENT_HV=dev
./scripts/gen_cp_flink_dinamic.sh \
  env-xxxxx \
  /ruta/PEVE-stream-processing-resources-v2/PEVE/ccloud-flink/desa/compute-pool \
  stacks/flink-compute-pool
```

En Actions se copia `iac/resources` → `./resources` y se corre el script antes del plan.

State DES: container `tf-flink-cps-dev`, key `dev/{CODAPP}/ccloud-flink/compute-pool/tf-flink-cps.tfstate`.
