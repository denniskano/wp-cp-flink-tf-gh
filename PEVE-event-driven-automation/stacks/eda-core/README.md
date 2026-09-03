# eda-core

Topics, Schema Registry, RBAC y data sources de SA. El HCL no está escrito a mano: lo arman los `generate_*_dinamic.sh` a partir de `resources/template/`.

En el runner se copia este directorio + los tpl a `./automation` y se corre `scripts/terraform_task.sh` (`-chdir=./automation`). El YAML sale de `PEVE-event-driven-resources-v3`.

Provider: Terraform `~> 1.12.2`, Confluent `~> 2.85.0`. El state vive en `tf-peve-resources`; la key la arma `terraform_task.sh` (ver [docs/STATE.md](../../docs/STATE.md)).
