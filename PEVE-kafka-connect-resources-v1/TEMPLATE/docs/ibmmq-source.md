# IBM MQ Source

Lee una cola o topic JMS de IBM MQ y produce a Kafka. Full-managed: clase `IbmMQSource`. Propiedades `mq.hostname` / `jms.destination.name` (no `mq.connection.name.list` ni `mq.queue` de Event Streams).

- Plantilla: [`../connects/ibmmq-source.yaml`](../connects/ibmmq-source.yaml)
- Doc oficial: [IBM MQ Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-ibmmq-source.html)

## YAML

Obligatorios: `kafka.topic`, `output.data.format` (`AVRO`, `JSON`, `JSON_SR`, `PROTOBUF`, `BYTES`, `STRING`), `mq.hostname`, `mq.queue.manager`, `jms.destination.name`.

Vault: `mq.username` y `mq.password`. En cliente MQ casi siempre hace falta `mq.channel` (el YAML de plantilla lo trae). Puerto default `1414`.

`BYTES` / `STRING` escriben el body JMS sin metadata. `AVRO` / `JSON_SR` / `PROTOBUF` piden Schema Registry.

El SA: **write** topic + `{topic}-value`.

El cluster es Dedicated + Private Link. EAP a un Private Link Service que publique MQ. `mq.hostname` es el FQDN del DNS del EAP.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.pending.messages` | `2000` | Mensajes por task antes de ack a MQ (0–20000). Más alto = más throughput y más duplicados si la task reinicia. Si ves `MQRC_BACKED_OUT` (2003), **bajalo** (ej. 2000 → 500). |
| `max.poll.duration` | — | Tiempo máximo armando un batch. Si la cola es lenta, un valor más bajo acota el lag (cierra el batch aunque no esté lleno). |
| `tasks.max` | — | Más tasks mejoran throughput. En cola, coordiná con MQ; en topic JMS usá subscription durable. |
| `jms.subscription.durable` / `jms.subscription.name` | — | Solo si `jms.destination.type: topic`. La subscription no se comparte. |
| `jms.message.selector` | — | Filtro JMS. Reduce volumen en origen. |
| `initial.poll.wait.time.ms` | `5000` | Espera del primer poll vacío. Bajalo si el arranque tarda de más. |
| `exactly.once.enabled` | `false` | EOS solo en conectores **nuevos**. Exige topic de estado en MQ (`state.topic.name`), creado **antes**. No se puede prender/apagar después. |

TLS: `mq.tls.keystore.location` / `mq.tls.truststore.location` van en Vault como `data:text/plain;base64,...`.
