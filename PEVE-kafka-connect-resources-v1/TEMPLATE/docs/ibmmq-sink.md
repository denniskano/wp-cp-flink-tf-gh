# IBM MQ Sink

Lee topics de Kafka y escribe a una cola o topic JMS de IBM MQ. Full-managed: clase `IbmMQSink`. En Configuration Properties las claves son `mq.hostname`, `mq.username`, `mq.queue.manager` (no el prefijo `ibm.mq.*` del snippet CLI).

- Plantilla: [`../connects/ibmmq-sink.yaml`](../connects/ibmmq-sink.yaml)
- Doc oficial: [IBM MQ Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-ibm-mq-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`, `BYTES`, `STRING`), `mq.hostname`, `mq.queue.manager`, `jms.destination.name`.

Vault: `mq.username` y `mq.password`. Agrega `mq.channel` y `mq.port` (`1414`) para cliente MQ.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

El cluster es Dedicated + Private Link. Se necesita un EAP a un Private Link Service que publique MQ. `mq.hostname` es el FQDN que resuelve el DNS de ese EAP, no la IP del PE.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `tasks.max` | — | Más tasks bajan consumer lag. No superes el número de particiones. Cada task abre sesión JMS. |
| `max.poll.records` | `500` | Records por poll. Reduce el valor si MQ no admite el pico de carga. |
| `max.poll.interval.ms` | `300000` | Auméntalo si el put a MQ tarda (cola llena, red). |
| `jms.connection.max.retries` | `5` | Reintentos de connect (0–25). |
| `jms.connection.backoff.ms` | `2000` | Espera entre reintentos (0–120000). |
| `jms.message.format` | `string` | `string`, `json` o `bytes`. Ajústalo a lo que espera el consumidor MQ. |
| `jms.forward.kafka.headers` | `false` | Si lo activas, los nombres de header tienen que ser identificadores Java (sin puntos). |
| `exactly.once.enabled` | `false` | Sesiones transaccionadas + offsets en MQ. Exige `mq.offsets.queue.name` (cola creada antes). |

`errors.tolerance: all` + DLQ para records que MQ rechaza. La cola destino y el channel tienen que existir; el usuario MQ necesita put.
