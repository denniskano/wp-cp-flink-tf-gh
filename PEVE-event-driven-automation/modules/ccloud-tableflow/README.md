# ccloud-tableflow

Esqueleto. Tableflow: materializa un topic Kafka a Iceberg/Delta en object storage (`confluent_tableflow_topic`).

Destino típico PEVE: ADLS / Azure. El topic debe existir (stack `eda-core`) **antes** de habilitar Tableflow.

Catalog (Glue, Unity, …) puede requerir `confluent_catalog_integration` en el mismo módulo cuando haya requisito; no es un stack aparte.

Unidad: use-case o topic. No mezclar con `kafka-connect`: el sink JDBC y Tableflow son destinos distintos.
