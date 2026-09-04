# MongoDB Atlas Sink

Lee topics y escribe documentos en MongoDB Atlas. Full-managed: clase `MongoDbAtlasSink`.

- Plantilla: [`../connects/mongodb-atlas-sink.yaml`](../connects/mongodb-atlas-sink.yaml)
- Doc oficial: [MongoDB Atlas Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink/cc-mongo-db-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `connection.host` (hostname Atlas, sin `mongodb+srv://`), `database`. `collection` opcional (si no, usa el topic).

Vault: `connection.user` y `connection.password`. El user de Atlas necesita write en la base de datos/colección.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

El Private Link del cluster Dedicated **no** alcanza Atlas. Se necesita Private Endpoint de Atlas + EAP en Confluent, o Atlas queda por internet (allowlist de egress). `connection.host` sigue siendo el hostname Atlas, no una IP.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.batch.size` | `0` (sin límite) | Records por bulk write. `0` = máximo throughput, más latencia/memoria. Reduce el valor si hay OOM o necesitas menos latencia; 1000–2000 es un punto habitual. |
| `max.num.retries` | `3` | Reintentos ante error de write. Auméntalo en prod si hay interrupciones breves de red. |
| `retries.defer.timeout` | `5000` | Espera entre reintentos (ms). |
| `tasks.max` | — | Ajústalo al número de particiones. |
| `max.poll.records` / `max.poll.interval.ms` | `500` / `300000` | Reduce `max.poll.records` si Atlas aplica throttle; aumenta `max.poll.interval.ms` si el bulk tarda. |
| `doc.id.strategy` | — | Cómo se construye `_id`. Full key = idempotente si el key de Kafka es estable. |
| `write.strategy` | — | Bulk write (insert vs replace/upsert). Upsert si hay reentregas. |
| `delete.on.null.values` | — | Tombstone Kafka → delete en Mongo. Solo si el compact + `_id` coinciden. |

El host es el de Atlas (`cluster0.xxxxx.mongodb.net`), no el URI completo. El user/password van en Vault, no en `connection.uri`.
