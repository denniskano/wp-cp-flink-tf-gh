# PostgreSQL Source

Lee tablas de PostgreSQL (JDBC) y produce a Kafka. Full-managed: clase `PostgresSource`. No usa `topics` ni `kafka.topic`: el topic es `{topic.prefix}{tabla}` (ej. `azc-app-pg-public.demo_events`).

- Plantilla: [`../connects/postgres-source.yaml`](../connects/postgres-source.yaml)
- Doc oficial: [PostgreSQL Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-source.html)

## YAML

Obligatorios: `topic.prefix`, `output.data.format`, `connection.host`, `connection.port` (5432), `db.name`, `table.include.list`. Formato: `AVRO`, `JSON_SR`, `PROTOBUF` o `JSON`.

`table.include.list` es regex sobre el nombre calificado (`schema.tabla`). `table.whitelist` está deprecado.

Vault: `connection.user` y `connection.password`. El usuario necesita `SELECT` en las tablas.

`ssl.mode`: `prefer` (default), `require` (recomendado en Azure), `verify-ca`, `verify-full`. Con `verify-*` el cert va en Vault (`ssl.rootcertfile`).

Modo de captura: `bulk` (default, full dump en cada poll). Con `timestamp.columns.mapping` pasa a timestamp; con `incrementing.column.mapping` a incrementing; ambos = timestamp+incrementing. Formato: `regex:[col1|col2]`. Cada tabla del include tiene que matchear **exactamente un** mapping. `timestamp.column.name` está deprecado.

El SA: **write** PREFIXED en `{topic.prefix}` (topic + subject). Confluent puede crear el topic (`partitions=1`, `rf=3`); si lo querés con otra config, crealo antes.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `poll.interval.ms` | `5000` | Cada cuánto poll a la DB. Bajalo si necesitás menos lag; subilo si la DB se satura. |
| `batch.max.rows` | `100` | Filas por batch JDBC. Subilo si el lag es por round-trips; bajalo ante locks o timeouts. |
| `tasks.max` | — | 1 task por tabla (tope). Más tasks que tablas no suma. |
| `timestamp.columns.mapping` | — | Incremental. La columna tiene que actualizarse en cada write y ser monótona. |
| `incrementing.column.mapping` | — | ID estrictamente creciente (ideal: PK). Junto con timestamp cubre updates + inserts únicos. |
| `db.timezone` | `UTC` | Timezone de las columnas timestamp. Desalinearlo duplica o saltea filas. |
| `table.exclude.list` | — | Regex a excluir si el include es amplio. |

Si recreás el conector (cambio de `name` o del archivo YAML) se pierden offsets: `bulk` vuelve a dump; timestamp/incrementing arranca desde el valor actual.
