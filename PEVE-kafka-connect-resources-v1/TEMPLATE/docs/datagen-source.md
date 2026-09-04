# Datagen Source

Genera datos de prueba hacia un topic de Kafka. Permite iniciar un flujo sin un sistema origen. No uses esto en producción con datos reales.

- Plantilla: [`../connects/datagen-source.yaml`](../connects/datagen-source.yaml)
- Doc oficial: [Datagen Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html)

## YAML

`connector.class`: `DatagenSource`. Topic en `kafka.topic`. Formato de salida: `AVRO`, `JSON_SR`, `PROTOBUF` o `JSON`.

Define **uno** de estos (son excluyentes):

- `quickstart`: schema de muestra (`TRANSACTIONS`, `PAGEVIEWS`, `ORDERS`, …). Lista completa en la doc oficial.
- `schema.string`: Avro JSON propio (máx. 10000 caracteres).

No hay secretos de Vault. El SA necesita **write** en el topic y en el subject `{topic}-value`.

No sale a un sistema externo: el Private Link de egreso no aplica.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.interval` | `1000` (ms) | Pausa máxima entre mensajes. Más bajo = más throughput. Mínimo 5 ms. |
| `tasks.max` | — | Más tasks = más particiones alimentadas en paralelo. Ajústalo al número de particiones del topic. |
| `iterations` | — | Límite de mensajes. Si no lo pones, corre hasta que lo pauses o lo destruyas. |
| `producer.override.linger.ms` | — | Agrupa records antes de enviar. Auméntalo si el topic recibe ráfagas pequeñas. |
| `producer.override.compression.type` | — | Compresión del producer (`lz4`, `snappy`, `gzip`, `zstd`). |

`output.data.format` con `AVRO` / `JSON_SR` / `PROTOBUF` exige Schema Registry. El schema del `quickstart` o de `schema.string` tiene que ser compatible con el que ya esté registrado en el subject.
