# HTTP Source V2

Llama APIs HTTP y produce a Kafka. Full-managed: clase `HttpSourceV2`. El topic **no** va en `topics`: va en `api1.topics` (y `apiN.topics` si hay más APIs).

- Plantilla: [`../connects/http-source.yaml`](../connects/http-source.yaml)
- Doc oficial: [HTTP Source V2 Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-http-source-v2.html)

## YAML

Obligatorios: `api1.topics`, `output.data.format` (`AVRO`, `JSON_SR` o `PROTOBUF`), `http.api.base.url`, `auth.type`, `apis.num` (`1`–`15`), `api1.http.request.method`.

`auth.type`:

| Valor | Vault |
|---|---|
| `NONE` (plantilla) | sin secretos |
| `BASIC` | user/password (props oficiales del conector) |
| `BEARER` | token |
| `OAUTH2` | client id/secret + token URL |
| `API_KEY` | API key |

`api1.http.offset.mode`: `SIMPLE_INCREMENTING` (default, plantilla), `CHAINING` (offset en el record), `CURSOR_PAGINATION` (next-page pointer). El modo define qué punteros JSON se necesitan.

El SA: **write** en `api1.topics` y `{topic}-value`.

El cluster es Dedicated + Private Link. `http.api.base.url` es el FQDN de la API. Si la API es privada en Azure, el EAP + DNS tienen que resolver ese dominio. APIs públicas de internet no pasan por el PE del cluster.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `api1.request.interval.ms` | — | Cada cuánto se llama la API. `60000` = 1 min. Reduce el valor si hay retraso; respeta los rate limits. |
| `api1.max.retries` | `5` | Reintentos ante error HTTP. |
| `api1.retry.backoff.policy` | `EXPONENTIAL_WITH_JITTER` | Mantén el default. Evita thundering herd. |
| `api1.retry.backoff.ms` | — | Base del backoff. |
| `api1.retry.on.status.codes` | — | Ej. `400-` reintenta 4xx/5xx. Ajusta si 404 es “no hay más”. |
| `api1.http.connect.timeout.ms` / `api1.http.request.timeout.ms` | `30000` | Timeouts. Auméntalos si la API es lenta. |
| `behavior.on.error` | `FAIL` | `IGNORE` sigue ante error de parse/API (puedes perder records). |
| `tasks.max` | — | En V2 suele ir 1 por API configurada; no multipliques sin ver la doc de la API. |

`https.ssl.enabled: true` en APIs públicas. Si recreas el conector se pierde el offset HTTP y `SIMPLE_INCREMENTING` / cursor vuelven a empezar.
