# Salesforce Platform Event Sink

Lee topics y publica Platform Events en Salesforce. Full-managed: clase `SalesforcePlatformEventSink`. El nombre del evento es `salesforce.platform.event1.name` (termina en `__e`), no `salesforce.platform.event.name`.

- Plantilla: [`../connects/salesforce-platform-event-sink.yaml`](../connects/salesforce-platform-event-sink.yaml)
- Doc oficial: [Salesforce Platform Event Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-platform-event-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR` o `PROTOBUF`), `salesforce.grant.type`, `salesforce.instance`, `salesforce.platform.event.num` (`1`–`5`), `salesforce.platform.event1.name` (case sensitive, sufijo `__e`).

Grant y secretos de Vault:

| `salesforce.grant.type` | Secretos |
|---|---|
| `PASSWORD` (default de la plantilla) | `salesforce.username`, `salesforce.password`, `salesforce.password.token`, `salesforce.consumer.key`, `salesforce.consumer.secret` |
| `CLIENT_CREDENTIALS` | `salesforce.consumer.key`, `salesforce.consumer.secret`. `salesforce.instance` tiene que ser la My Domain (no `login.salesforce.com`). |
| `JWT_BEARER` | `salesforce.username`, `salesforce.consumer.key`, `salesforce.jwt.keystore.file`, `salesforce.jwt.keystore.password` |
| `OAUTH2_AUTH_CODE_BYOA` | `salesforce.consumer.key`, `salesforce.consumer.secret` + handshake en la UI de Confluent |

Confluent depreca `PASSWORD` el **15-sep-2026**. Para algo que vaya a vivir, usá `CLIENT_CREDENTIALS` o `JWT_BEARER`.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

El Private Link del cluster Dedicated **no** alcanza Salesforce. `salesforce.instance` (`login.salesforce.com` o My Domain) sale por internet salvo que haya Private Connect / EAP propio.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `tasks.max` | — | Más tasks bajan consumer lag. Cuidado con los límites de eventos/hora de Salesforce. |
| `max.poll.records` | `500` | Bajalo si Salesforce responde 503 / `REQUEST_LIMIT_EXCEEDED`. |
| `max.poll.interval.ms` | `300000` | Subilo si el publish tarda (reintentos). |
| `request.max.retries.time.ms` | `30000` | Ventana de reintento de API (1000–250000). Subilo ante throttling transitorio. |
| `connection.timeout` | `30000` | Timeout del endpoint Streaming. |
| `behavior.on.api.errors` | `ignore` | `fail` tumba la task ante error de API. `ignore` sigue (el record puede perderse si no hay DLQ). |
| `salesforce.platform.event.num` | — | Hasta 5 eventos. Cada uno tiene `salesforce.platform.eventN.name` y opcional `…eventN.topics`. |

El usuario de integración necesita API Enabled y permiso de create/publish en el Platform Event. Si el evento no llega, revisá el case del nombre (`App_Event__e` ≠ `app_event__e`) y el grant.
