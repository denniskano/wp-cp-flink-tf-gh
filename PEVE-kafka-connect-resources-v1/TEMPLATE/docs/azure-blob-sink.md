# Azure Blob Storage Sink

Lee topics y escribe archivos en un container de Blob Storage. Full-managed: clase `AzureBlobSink`.

- Plantilla: [`../connects/azure-blob-sink.yaml`](../connects/azure-blob-sink.yaml)
- Doc oficial: [Azure Blob Storage Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-sink/cc-azure-blob-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`, `BYTES`), `output.data.format` (`AVRO`, `JSON`, `BYTES`), `azblob.account.name`, `azblob.container.name`, `time.interval` (`HOURLY` o `DAILY`; TimeBasedPartitioner es el default).

Vault: `azblob.account.key`.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

El cluster es Dedicated + Private Link. `azblob.account.name` es el account; el EAP (sub-recurso `blob`) + DNS (`*.blob.core.windows.net`) resuelven al PE.

`topics.dir` + `path.format` arman el path. Ejemplo con `time.interval: HOURLY` y `topics.dir: json_logs/hourly`: `{container}/json_logs/hourly/{topic}/dt=2020-02-06/hr=09/`.

## Tuning

El archivo se cierra cuando se cumple **la primera** de estas condiciones: `flush.size`, `rotate.interval.ms` o `rotate.schedule.interval.ms`.

| Propiedad | Default | Para qué |
|---|---|---|
| `flush.size` | `1000` | Records por archivo. La plantilla usa 1000 para no generar miles de archivos pequeños. |
| `time.interval` | — | `HOURLY` o `DAILY`. Cierra el archivo al cruzar el borde de hora/día. |
| `rotate.schedule.interval.ms` | `-1` (off) | Cierra por reloj (ej. `600000` = cada 10 min) aunque no llegue `flush.size`. **Rompe exactly-once.** |
| `rotate.interval.ms` | = `time.interval` | Cierra cuando el timestamp del record sale del span del primer record del archivo. Necesita stream continuo. |
| `tasks.max` | — | Ajústalo al número de particiones del topic. |
| `max.poll.records` / `max.poll.interval.ms` | `500` / `300000` | Igual que otros sinks: reduce `max.poll.records` si un flush tarda; aumenta `max.poll.interval.ms` si Azure está lento. |
| `az.compression.type` | — | Compresión del objeto en Blob. |

Si el topic es de bajo volumen y necesitas ver archivos cada N minutos, usa `rotate.schedule.interval.ms`. Si necesitas exactly-once, no lo uses: espera `flush.size` o el borde de `time.interval`.
