# Microsoft SQL Server Source

Lee tablas de SQL Server / Azure SQL (JDBC) y produce a Kafka. Full-managed: clase `MicrosoftSqlServerSource`. No usa `topics` ni `kafka.topic`: el topic es `{topic.prefix}{tabla}` (ej. `azc-app-sql-dbo.demo_events`).

- Plantilla: [`../connects/sqlserver-source.yaml`](../connects/sqlserver-source.yaml)
- Doc oficial: [Microsoft SQL Server Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source.html)

## YAML

Obligatorios: `topic.prefix`, `output.data.format`, `connection.host`, `connection.port` (1433 en Azure SQL), `db.name`, `table.include.list`. Formato: `AVRO`, `JSON_SR`, `PROTOBUF` o `JSON`.

`table.include.list` es regex sobre el nombre calificado (`schema.tabla`). En Azure SQL el schema típico es `dbo`.

Vault: `connection.user` y `connection.password`. El login necesita `SELECT`.

`ssl.mode`: `prefer`, `require` (típico en Azure SQL), `verify-ca`, `verify-full`.

Modo: `bulk` por default. `timestamp.columns.mapping` / `incrementing.column.mapping` para incremental. Formato `regex:[col]`. `timestamp.column.name` está deprecado.

El SA: **write** PREFIXED en `{topic.prefix}` (topic + subject). Creá el topic antes si no querés el default (`partitions=1`, `rf=3`).

El cluster es Dedicated + Private Link. `connection.host` es el FQDN; el EAP + DNS lo resuelven al PE.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `poll.interval.ms` | `5000` | Frecuencia de poll. Bajalo para menos lag; subilo si SQL se satura. |
| `batch.max.rows` | `100` | Filas por batch. Subilo si el bottleneck es red; bajalo ante locks. |
| `tasks.max` | — | 1 task por tabla. |
| `timestamp.columns.mapping` | — | Incremental por columna datetime. Tiene que actualizarse en cada write. |
| `incrementing.column.mapping` | — | Columna estrictamente creciente. Junto con timestamp = menos huecos en updates. |
| `db.timezone` | `UTC` | Alinealo a `datetime` / `datetime2`. |
| `table.types` | `TABLE` | `VIEW` solo si la vista es estable y tenés SELECT. |

CDC nativo de SQL Server no es este conector: acá es JDBC (poll). Si recreás el conector se pierden offsets.
