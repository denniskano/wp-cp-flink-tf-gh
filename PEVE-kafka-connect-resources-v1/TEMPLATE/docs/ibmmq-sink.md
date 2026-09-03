# IBM MQ Sink

Lee topics de Kafka y escribe a una cola o topic JMS de IBM MQ. Full-managed: clase `IbmMQSink`. En Configuration Properties las claves son `mq.hostname`, `mq.username`, `mq.queue.manager` (no el prefijo `ibm.mq.*` del snippet CLI).

- Plantilla: [`../connects/ibmmq-sink.yaml`](../connects/ibmmq-sink.yaml)
- Doc oficial: [IBM MQ Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-ibm-mq-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`, `BYTES`, `STRING`), `mq.hostname`, `mq.queue.manager`, `jms.destination.name`.

Vault: `mq.username` y `mq.password`. Sumá `mq.channel` y `mq.port` (`1414`) para cliente MQ.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `tasks.max` | — | Más tasks bajan consumer lag. No pases las particiones. Cada task abre sesión JMS. |
| `max.poll.records` | `500` | Records por poll. Tope 500 en no Dedicated. Bajalo si MQ no banca el burst. |
| `max.poll.interval.ms` | `300000` | Subilo si el put a MQ tarda (cola llena, red). |
| `jms.connection.max.retries` | `5` | Reintentos de connect (0–25). |
| `jms.connection.backoff.ms` | `2000` | Espera entre reintentos (0–120000). |
| `jms.message.format` | `string` | `string`, `json` o `bytes`. Alinealo a lo que espera el consumidor MQ. |
| `jms.forward.kafka.headers` | `false` | Si lo prendés, los nombres de header tienen que ser identificadores Java (sin puntos). |
| `exactly.once.enabled` | `false` | Sesiones transaccionadas + offsets en MQ. Exige `mq.offsets.queue.name` (cola creada antes). |

`errors.tolerance: all` + DLQ para records que MQ rechaza. La cola destino y el channel tienen que existir; el usuario MQ necesita put.
