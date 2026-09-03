# Azure Blob Storage Source

Lee objetos de un container de Blob Storage y produce a Kafka. Full-managed: clase `AzureBlobSource`. El topic va en `topic.regex.list` (`topic:regex`), no en `topics` / `kafka.topic`.

- Plantilla: [`../connects/azure-blob-source.yaml`](../connects/azure-blob-source.yaml)
- Doc oficial: [Azure Blob Storage Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-source.html)

## YAML

Obligatorios: `topic.regex.list`, `input.data.format`, `azblob.account.name`, `azblob.container.name`.

`topic.regex.list` es `topic:regex` (coma si hay varios). El regex matchea el **path completo** (`folder/file.json`), no solo el filename. `azc-app-demo-input:.*` manda todo el container a ese topic. Si un archivo matchea varios, gana el primero.

Vault: `azblob.account.key`.

El SA: **write** en el topic del mapping y `{topic}-value`.

El cluster es Dedicated + Private Link. `azblob.account.name` + EAP (sub-recurso `blob`) + DNS (`*.blob.core.windows.net`).

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `azblob.poll.interval.ms` | `60000` | Cada cuánto lista el container. Bajalo si necesitás menos lag; listar mucho cuesta en Storage. |
| `azblob.retry.type` | `EXPONENTIAL` | Dejalo. |
| `tasks.max` | — | Más tasks = más lecturas en paralelo. |
| `input.data.format` | — | Tiene que coincidir con el objeto (`JSON`, `AVRO`, `BYTES`, …). Un mismatch tumba la task o manda basura. |

Archivos ya procesados no se relean salvo que recreés el conector (se pierden offsets). No escribas/modifiques blobs que el source ya vio: el conector no hace CDC de overwrite.
