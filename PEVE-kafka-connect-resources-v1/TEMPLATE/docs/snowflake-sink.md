# Snowflake Sink

Lee topics y escribe en Snowflake (Snowpipe o Snowpipe Streaming). Full-managed: clase `SnowflakeSink`.

- Plantilla: [`../connects/snowflake-sink.yaml`](../connects/snowflake-sink.yaml)
- Doc oficial: [Snowflake Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-snowflake-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `snowflake.url.name` (`https://<account>.<region>.<cloud>.snowflakecomputing.com:443`), `snowflake.database.name`, `snowflake.schema.name`.

Vault: `snowflake.user.name` y `snowflake.private.key` (key-pair). El user necesita rol con ingest en la DB/schema (`snowflake.role.name`).

`snowflake.ingestion.method`: `SNOWPIPE_STREAMING` (plantilla, menor latencia) o `SNOWPIPE`.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

El Private Link del cluster Dedicated **no** alcanza Snowflake. Se necesita Private Connectivity de Snowflake + EAP, o el `snowflake.url.name` queda por internet.

## Tuning

El flush ocurre cuando se cumple **la primera** de `buffer.count.records`, `buffer.size.bytes` o `buffer.flush.time`.

| Propiedad | Default | Para qué |
|---|---|---|
| `buffer.flush.time` | `120` s | Máxima latencia del buffer. Mín. 10 s (`SNOWPIPE`) / 1 s (`SNOWPIPE_STREAMING`). Más bajo = más files/canales y más costo. |
| `buffer.count.records` | `10000` | Records antes de flush. |
| `buffer.size.bytes` | `10000000` (10 MB) | Bytes del canal. Más grande = menos flushes, más memoria. En Streaming hay un límite de canales vs tamaño. |
| `snowflake.ingestion.method` | — | `SNOWPIPE_STREAMING` para near-real-time. `SNOWPIPE` si ya operas por stage/pipe. |
| `tasks.max` | — | Ajústalo al número de particiones. Cada task = canal/conexión. |
| `max.poll.records` / `max.poll.interval.ms` | `500` / `300000` | Aumenta `max.poll.interval.ms` si Snowflake tarda el ingest. |

La private key es PKCS#8 (sin passphrase en CCloud, o la que documente el conector). No pongas user/key en claro.
