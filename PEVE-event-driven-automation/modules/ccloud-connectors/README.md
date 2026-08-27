# ccloud-connectors

Full-managed Kafka Connect. Lee `{connectors_dir}/*.yaml` y `{security_dir}/*.yaml` del repo de resources (inyectados por el workflow).

Key de `for_each` = nombre del archivo sin `.yaml`. Borrar un YAML destruye solo ese conector.

Custom SMT **no** se sube aquí: stack `connect-plugins`. El YAML solo lleva `transforms.*.custom.smt.artifact.id`.
