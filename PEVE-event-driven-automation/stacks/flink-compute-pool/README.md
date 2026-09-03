# Stack: flink-compute-pool

Raíz Terraform. Los pools los genera **codegen** (`scripts/gen_cp_flink_dinamic.sh` + `resources/template/cp_flink.tf.tpl`), igual que v2.

```bash
export ENVIRONMENT_HV=dev
./scripts/gen_cp_flink_dinamic.sh \
  env-xxxxx \
  /path/to/PEVE-stream-processing-resources-v2/PEVE/ccloud-flink/desa/compute-pool \
  stacks/flink-compute-pool
# escribe stacks/flink-compute-pool/cp_flink.tf
```

El workflow copia `iac/resources` → `./resources` y corre el script **antes** de `terraform plan`.

State DES: `dev/{CODAPP}/ccloud-flink/compute-pool/tf-flink-cps.tfstate` (container `tf-flink-cps-dev`).
