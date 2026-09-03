# MySQL Sink

Lee un topic y escribe filas en MySQL / Azure Database for MySQL. Full-managed: clase `MySqlSink`.

- Plantilla: [`../connects/mysql-sink.yaml`](../connects/mysql-sink.yaml)
- Doc oficial: [MySQL Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-mysql-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host`, `connection.port` (3306), `db.name`. Formato: `AVRO`, `JSON_SR`, `PROTOBUF`, `JSON` o `STRING`.

Vault: `connection.user` y `connection.password`. El usuario necesita `INSERT`/`UPDATE` (y `CREATE`/`ALTER` solo si usás `auto.create` / `auto.evolve`).

`ssl.mode`: `prefer` (default), `require` (recomendado en Azure), `verify-ca`, `verify-full`. Con `verify-*` el cert va en Vault.

El SA: **read** topic + subject, **write/read** en `{topic}-dlq` si hay `errors.tolerance`, y `group` PREFIXED `connect-lcc-`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `insert.mode` | `INSERT` | `UPSERT` si hay PK y reintentos/duplicados. `INSERT` falla si la fila ya existe. |
| `batch.sizes` | `3000` | Filas por batch JDBC (1–5000). Bajalo si MySQL se satura; subilo si el lag es por round-trips. |
| `tasks.max` | — | Más tasks = más consumidores. No pases las particiones. Cada task abre conexión. |
| `max.poll.records` | `500` | Records por poll. Tope 500 en clusters no Dedicated. |
| `max.poll.interval.ms` | `300000` | Si el sink tarda en escribir, subilo para no rebalancear. |
| `pk.mode` / `pk.fields` | — | Obligatorio para `UPSERT`. |
| `auto.create` / `auto.evolve` | `false` | Dejalos en `false`. El DDL lo versionás vos. |
| `table.name.format` | `${topic}` | Nombre de tabla. Cuidado con el largo de identifiers de MySQL. |

`errors.tolerance: all` manda el record fallido al DLQ y sigue. `none` tumba la task. El topic DLQ tiene que existir de antemano.
