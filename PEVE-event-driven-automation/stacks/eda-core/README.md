# Stack: eda-core

Raíz Terraform (codegen, igual que Flink). Topics, Schema Registry, RBAC y lookup de SA.

- `scripts/generate_topic_dinamic.sh`
- `scripts/generate_schema_registry_dinamic.sh`
- `scripts/generate_rbac_dinamic.sh`
- Orquesta: `scripts/terraform_task.sh` (`-chdir=./automation`)

Templates: `resources/template/{topics,topics_tag,rbac,data_sa,schema_registry,schema_registry_mode,confluent_subject_config}.tf.tpl`.

En CI se copia este stack + esos templates a `./automation` (los `generate_*` y `terraform_task` siguen usando `./automation`). YAML: `PEVE-event-driven-resources-v3`.
