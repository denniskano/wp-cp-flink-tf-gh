# PostgreSQL Sink

Lee un topic y escribe filas en PostgreSQL (JDBC). Full-managed: clase `PostgresSink`.

- Plantilla: [`../connects/postgres-sink.yaml`](../connects/postgres-sink.yaml)
- Doc oficial: [PostgreSQL Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host`, `connection.port`, `db.name`. Formato de entrada: `AVRO`, `JSON_SR`, `PROTOBUF`, `JSON` o `STRING`.

Vault: `connection.user` y `connection.password`. El usuario de la DB necesita `INSERT`/`UPDATE` (y `CREATE`/`ALTER` solo si usás `auto.create` / `auto.evolve`).

`ssl.mode`: `prefer` (default, cae a no-SSL), `require` (recomendado en Azure), `verify-ca`, `verify-full`. Con `verify-*` hace falta el cert en Vault (`ssl.rootcertfile`).

El SA necesita **read** en topic + subject, **write/read** en `{topic}-dlq` si hay `errors.tolerance`, y `group` PREFIXED `connect-lcc-`.

El cluster es Dedicated + Private Link. `connection.host` es el FQDN público (`*.postgres.database.azure.com`); el EAP + DNS lo resuelven al PE. No pongas la IP privada.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `insert.mode` | `INSERT` | `UPSERT` si hay PK y reintentos/duplicados. `INSERT` falla si la fila ya existe. |
| `batch.sizes` | `3000` | Filas por batch JDBC (1–5000). Bajalo si el DB se satura; subilo si el lag es por round-trips. |
| `tasks.max` | — | Más tasks = más consumidores. No pases las particiones del topic. Cada task abre conexión. |
| `max.poll.records` | `500` | Records por poll. En Dedicated no aplica el tope 500 de Basic/Standard; subilo si el DB lo banca. |
| `max.poll.interval.ms` | `300000` | Si el sink tarda en escribir, subilo para no rebalancear. Dedicated permite rangos más amplios que Basic/Standard. |
| `pk.mode` / `pk.fields` | — | Obligatorio para `UPSERT`. `record_value` usa campos del value; `record_key` el key. |
| `auto.create` / `auto.evolve` | `false` | Dejalos en `false` en DES/CERT/PROD. El DDL lo versionás vos. |
| `table.name.format` | `${topic}` | Nombre de tabla. PostgreSQL trunca a 63 caracteres: topics largos pueden colisionar. |

`errors.tolerance: all` manda el record fallido al DLQ (`{topic}-dlq`, lo arma el stack) y sigue. `none` tumba la task. El topic DLQ tiene que existir de antemano.
