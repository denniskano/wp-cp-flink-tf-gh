# MySQL Sink

Lee un topic y escribe filas en MySQL / Azure Database for MySQL. Full-managed: clase `MySqlSink`.

- Plantilla: [`../connects/mysql-sink.yaml`](../connects/mysql-sink.yaml)
- Doc oficial: [MySQL Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-mysql-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host`, `connection.port` (3306), `db.name`. Formato: `AVRO`, `JSON_SR`, `PROTOBUF`, `JSON` o `STRING`.

Vault: `connection.user` y `connection.password`. El usuario necesita `INSERT`/`UPDATE` (y `CREATE`/`ALTER` solo si usas `auto.create` / `auto.evolve`).

`ssl.mode`: `prefer` (default), `require` (recomendado en Azure), `verify-ca`, `verify-full`. Con `verify-*` el cert va en Vault.

El SA: **read** topic + subject, **write/read** en `{topic}-dlq` si hay `errors.tolerance`, y `group` PREFIXED `connect-lcc-`.

El cluster es Dedicated + Private Link. `connection.host` es el FQDN; el EAP + DNS lo resuelven al PE.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `insert.mode` | `INSERT` | `UPSERT` si hay PK y reintentos/duplicados. `INSERT` falla si la fila ya existe. |
| `batch.sizes` | `3000` | Filas por batch JDBC (1–5000). Reduce el valor si MySQL se satura; auméntalo si el retraso se debe a round-trips. |
| `tasks.max` | — | Más tasks = más consumidores. No superes el número de particiones. Cada task abre conexión. |
| `max.poll.records` | `500` | Records por poll. Aumenta el valor si MySQL lo admite. |
| `max.poll.interval.ms` | `300000` | Si el sink tarda en escribir, auméntalo para evitar un rebalance. |
| `pk.mode` / `pk.fields` | — | Obligatorio para `UPSERT`. |
| `auto.create` / `auto.evolve` | `false` | Mantén `false`. El DDL se versiona fuera del conector. |
| `table.name.format` | `${topic}` | Nombre de tabla. Ten en cuenta el largo de identifiers de MySQL. |

`errors.tolerance: all` envía el record fallido al DLQ y sigue. `none` detiene la task. El topic DLQ tiene que existir de antemano.
