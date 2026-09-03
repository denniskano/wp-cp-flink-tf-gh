# Azure Event Hubs Sink (HttpSinkV2)

Confluent Cloud **no tiene** un conector `AzureEventHubsSink`. En el [catálogo oficial](https://docs.confluent.io/cloud/current/connectors/overview.html) solo figura **Azure Event Hubs Source**. Para escribir desde Kafka hacia un Event Hub usá el sink full-managed **HTTP Sink V2** contra la [API REST Send Event](https://learn.microsoft.com/en-us/rest/api/eventhub/send-event).

- Plantilla: [`../connects/eventhubs-sink.yaml`](../connects/eventhubs-sink.yaml)
- Doc oficial (conector): [HTTP Sink V2 Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-http-sink-v2.html)
- Doc oficial (destino): [Send event (Event Hubs REST)](https://learn.microsoft.com/en-us/rest/api/eventhub/send-event)

## YAML

`connector.class`: `HttpSinkV2` (no inventes `AzureEventHubsSink`: el apply de Confluent lo rechaza).

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`, `BYTES`, `STRING`), `http.api.base.url`, `auth.type`, `apis.num` (1–15), `api1.http.request.method`.

Para Event Hubs:

| Campo | Valor |
|---|---|
| `http.api.base.url` | `https://{namespace}.servicebus.windows.net` |
| `api1.http.api.path` | `/{eventhub}/messages` |
| `api1.http.request.method` | `POST` |
| `https.ssl.enabled` | `true` |
| `auth.type` | `OAUTH2` (recomendado) |

La app de Entra ID necesita el rol **Azure Event Hubs Data Sender** en el namespace o el hub. Token:

- `oauth2.token.url`: `https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token`
- `oauth2.client.scope`: `https://eventhubs.azure.net/.default`

Vault (`OAUTH2`): `oauth2.client.id` y `oauth2.client.secret`.

SAS (`auth.type: BEARER` + `bearer.token`) manda `Authorization: Bearer …`. Event Hubs espera `SharedAccessSignature …`, así que SAS no encaja bien. Si no podés usar Entra ID, poné el SAS en un header sensible (`api1.http.request.sensitive.headers`) con `auth.type: NONE` y rotá el token en Vault **antes** de que expire.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `api1.max.batch.size` | `1` | Records por request HTTP. Send Event es **un evento por POST**. Dejá `1`. Un batch > 1 no es el API de batch de Event Hubs. |
| `tasks.max` | — | Más tasks = más POSTs en paralelo. Cuidado con TU (throughput units) del namespace. |
| `max.poll.records` | `500` | Bajalo si Event Hubs responde 429 / `ServerBusy`. Tope 500 en no Dedicated. |
| `max.poll.interval.ms` | `300000` | Subilo si los reintentos HTTP alargan el ciclo. |
| `api1.max.retries` | `5` | Reintentos (1–5000) ante códigos de `api1.retry.on.status.codes`. |
| `api1.retry.backoff.ms` | `3000` | Pausa base. Con `EXPONENTIAL_WITH_JITTER` crece en cada retry. |
| `api1.retry.on.status.codes` | `400-` | Rango a reintentar. `429` y `5xx` tienen que estar cubiertos. |
| `api1.http.request.timeout.ms` | `30000` | Timeout del POST a Event Hubs. |
| `api1.http.connect.timeout.ms` | `30000` | Timeout del handshake TLS. |
| `behavior.on.error` | `FAIL` | `FAIL` tumba la task. `IGNORE` sigue (riesgo de pérdida si no hay DLQ). |

`errors.tolerance: all` + topic `{topic}-dlq` (lo arma el stack) para records que Event Hubs rechaza (401, 404 hub inexistente, payload inválido). El hub y el namespace tienen que existir; Private Link si el cluster no sale a internet.
