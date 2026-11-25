# temporal-cloud

Lee `{CODAPP}/{dev|cert|prod}/namespaces/*.yaml` y `nexus/*.yaml`.

`IS_ONLY` no aplica: un apply trae todo el env.

Prod: el YAML debe traer **dos** regiones que sean par HA ([TEMPORAL-HA.md](../../docs/TEMPORAL-HA.md)).
