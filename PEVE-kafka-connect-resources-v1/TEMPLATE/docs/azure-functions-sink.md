# Azure Functions Sink

Lee un topic e invoca una Azure Function HTTP. Full-managed: clase `AzureFunctionsSink`.

- Plantilla: [`../connects/azure-functions-sink.yaml`](../connects/azure-functions-sink.yaml)
- Doc oficial: [Azure Functions Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-functions-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format`, `function.url` (`https://…azurewebsites.net/api/…`).

Vault: `function.key` (function o host key).

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

Azure Functions: tope **100 MB** por request y timeout ~**230 s**.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.batch.size` | `1` | Records por invocación (1–1000). `1` = sin batch. Subilo si hay lag o duplicados porque el consumer no termina el poll a tiempo. Un batch grande puede pasar 100 MB y fallar. |
| `max.poll.records` | `500` | Alinealo a `max.batch.size` para no dejar records colgados en el poll. |
| `max.poll.interval.ms` | `300000` | Subilo si la function tarda (reintentos, cold start). |
| `max.pending.requests` | `1` | Invocaciones en vuelo. Subilo para más paralelismo; la function tiene que bancarlo (plan / concurrency). |
| `tasks.max` | — | Alinealo a particiones. |
| `request.timeout` | — | Timeout HTTP hacia la function. No lo pongas por debajo del p99 de ejecución. |

Si ves duplicados en la function, el consumer está lento: subí `max.batch.size` y `max.pending.requests`. La function tiene que ser **idempotente** (at-least-once).
