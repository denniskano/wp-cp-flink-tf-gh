# Microsoft SQL Server Sink

Lee un topic y escribe filas en SQL Server / Azure SQL. Full-managed: clase `MicrosoftSqlServerSink` (no `MicrosoftSqlserverSink`).

- Plantilla: [`../connects/sqlserver-sink.yaml`](../connects/sqlserver-sink.yaml)
- Doc oficial: [Microsoft SQL Server Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host`, `connection.port` (1433 en Azure SQL), `db.name`. Formato: `AVRO`, `JSON_SR`, `PROTOBUF`, `JSON` o `STRING`.

Vault: `connection.user` y `connection.password`. El login necesita `INSERT`/`UPDATE` en las tablas destino.

`ssl.mode`: `prefer`, `require` (típico en Azure SQL), `verify-ca`, `verify-full`. Con `verify-*` el truststore va en Vault.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `insert.mode` | `INSERT` | `UPSERT` si hay PK y el conector reentrega. `INSERT` falla en duplicado. |
| `batch.sizes` | `3000` | Filas por batch (1–5000). Bajalo ante timeouts o locks; subilo si el bottleneck es red. |
| `tasks.max` | — | Alinealo a particiones. Cada task = más carga en SQL. |
| `max.poll.records` | `500` | Tope 500 en no Dedicated. Bajalo si un poll no entra en `max.poll.interval.ms`. |
| `max.poll.interval.ms` | `300000` | Subilo si SQL tarda (locks, índices faltantes). |
| `pk.mode` / `pk.fields` | — | Hace falta para `UPSERT`. |
| `table.types` | `TABLE` | Dejá `TABLE`. `VIEW` solo si SQL acepta writes y el schema coincide. |
| `db.timezone` | — | Alinealo al timezone de las columnas `datetime`. |
| `auto.create` / `auto.evolve` | `false` | Dejalos en `false`. El schema de la tabla lo controlás vos. |

Si ves consumer lag y CPU de SQL baja, subí `batch.sizes` o `tasks.max`. Si ves timeouts o deadlocks, bajá batch y poll y revisá índices de la PK.
