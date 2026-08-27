# Stack: eda-core

Esqueleto. Topics, schemas, RBAC de cluster y **service accounts / API keys del use-case**.

No hay stack `identity` aparte: el principal del conector o del statement nace aquí; Connect/Flink solo hacen lookup por `display_name`.
