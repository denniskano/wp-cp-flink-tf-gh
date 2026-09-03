# Datagen Source

Genera datos de prueba hacia un topic de Kafka. Sirve para levantar un flujo sin un sistema origen. No uses esto en producción con datos reales.

- Plantilla: [`../connects/datagen-source.yaml`](../connects/datagen-source.yaml)
- Doc oficial: [Datagen Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html)

## YAML

`connector.class`: `DatagenSource`. Topic en `kafka.topic`. Formato de salida: `AVRO`, `JSON_SR`, `PROTOBUF` o `JSON`.

Definí **uno** de estos (son excluyentes):

- `quickstart`: schema de muestra (`TRANSACTIONS`, `PAGEVIEWS`, `ORDERS`, …). Lista completa en la doc oficial.
- `schema.string`: Avro JSON propio (máx. 10000 caracteres).

No hay secretos de Vault. El SA necesita **write** en el topic y en el subject `{topic}-value`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.interval` | `1000` (ms) | Pausa máxima entre mensajes. Más bajo = más throughput. Mínimo 10 ms (5 ms en Dedicated). |
| `tasks.max` | — | Más tasks = más particiones alimentadas en paralelo. Alinealo a las particiones del topic. |
| `iterations` | — | Tope de mensajes. Si no lo pones, corre hasta que lo pauses o lo destruyas. |
| `producer.override.linger.ms` | — | Agrupa records antes de enviar. Subilo si el topic recibe ráfagas chicas. |
| `producer.override.compression.type` | — | Compresión del producer (`lz4`, `snappy`, `gzip`, `zstd`). |

`output.data.format` con `AVRO` / `JSON_SR` / `PROTOBUF` exige Schema Registry. El schema del `quickstart` o de `schema.string` tiene que ser compatible con el que ya esté registrado en el subject.
