# PostgreSQL Sink

Lee un topic y escribe filas en PostgreSQL (JDBC). Full-managed: clase `PostgresSink`.

- Plantilla: [`../connects/postgres-sink.yaml`](../connects/postgres-sink.yaml)
- Doc oficial: [PostgreSQL Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host`, `connection.port`, `db.name`. Formato de entrada: `AVRO`, `JSON_SR`, `PROTOBUF`, `JSON` o `STRING`.

Vault: `connection.user` y `connection.password`. El usuario de la base de datos necesita `INSERT`/`UPDATE` (y `CREATE`/`ALTER` solo si usas `auto.create` / `auto.evolve`).

`ssl.mode`: `prefer` (default, pasa a una conexión sin SSL), `require` (recomendado en Azure), `verify-ca`, `verify-full`. Con `verify-*` se necesita el cert en Vault (`ssl.rootcertfile`).

El SA necesita **read** en topic + subject, **write/read** en `{topic}-dlq` si hay `errors.tolerance`, y `group` PREFIXED `connect-lcc-`.

El cluster es Dedicated + Private Link. `connection.host` es el FQDN público (`*.postgres.database.azure.com`); el EAP + DNS lo resuelven al PE. No pongas la IP privada.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `insert.mode` | `INSERT` | `UPSERT` si hay PK y reintentos/duplicados. `INSERT` falla si la fila ya existe. |
| `batch.sizes` | `3000` | Filas por batch JDBC (1–5000). Reduce el valor si la base de datos se satura; auméntalo si el retraso se debe a round-trips. |
| `tasks.max` | — | Más tasks = más consumidores. No superes el número de particiones del topic. Cada task abre conexión. |
| `max.poll.records` | `500` | Records por poll. Aumenta el valor si la base de datos lo admite. |
| `max.poll.interval.ms` | `300000` | Si el sink tarda en escribir, auméntalo para evitar un rebalance. |
| `pk.mode` / `pk.fields` | — | Obligatorio para `UPSERT`. `record_value` usa campos del value; `record_key` el key. |
| `auto.create` / `auto.evolve` | `false` | Mantén `false` en DES/CERT/PROD. El DDL se versiona fuera del conector. |
| `table.name.format` | `${topic}` | Nombre de tabla. PostgreSQL trunca a 63 caracteres: topics largos pueden colisionar. |

`errors.tolerance: all` envía el record fallido al DLQ (`{topic}-dlq`, lo crea el stack) y sigue. `none` detiene la task. El topic DLQ tiene que existir de antemano.

## Más volumen de escritura

El conector solo empuja más filas si PostgreSQL las absorbe. Subir `batch.sizes`, `tasks.max` o `max.poll.records` sin tocar la base satura conexiones, WAL o IOPS y el lag no baja.

Casos típicos:

| Caso | Señal | En el conector | En PostgreSQL |
|---|---|---|---|
| Produce sostenido mayor que el sink | Consumer lag crece; CPU de la base baja | Aumenta `batch.sizes` (hacia 3000–5000) y `max.poll.records` | PK/unique listos. Quita índices y FK que no hacen falta en el ingest. Revisa IOPS y vCores del SKU. |
| Pico o cierre de día | Lag en ráfaga, luego se recupera | Aumenta `tasks.max` (≤ particiones del topic) | `max_connections` con margen (1 conexión por task + app + admin). En Azure Flexible el límite depende del SKU. |
| Backfill / replay del topic | Lag enorme al recrear el conector o al leer desde el inicio | `INSERT` + batch alto; `UPSERT` si hay reentregas | Autovacuum más agresivo (`autovacuum_vacuum_scale_factor` más bajo o más `autovacuum_max_workers` / `autovacuum_vacuum_cost_limit`). Aumenta `max_wal_size` para no encadenar checkpoints. Crea índices no únicos **después** de la carga. |
| `UPSERT` lento | Write time alto, locks en la PK | `pk.mode` + `pk.fields` correctos; no aumentes tasks si hay contención en la misma clave | Índice unique en las columnas del conflicto (`ON CONFLICT`). Evita triggers y RLS en esa tabla durante el pico. |
| Timeouts o deadlocks al subir batch | Task se reinicia; el ciclo no entra en `max.poll.interval.ms` | Reduce `batch.sizes` y `max.poll.records`; aumenta `max.poll.interval.ms` | Consultas largas sobre la misma tabla. Particiona o mueve reportes a réplica. No uses PgBouncer en *transaction pooling*: el JDBC sink usa prepared statements; conecta directo o *session*. |

Antes de aumentar tasks, revisa en la base: `pg_stat_activity` (conexiones y waits), `pg_stat_user_tables` (`n_tup_ins` / `n_dead_tup`), IOPS y CPU del Flexible Server. Si el disco o el SKU ya están al límite, el YAML no alcanza.
