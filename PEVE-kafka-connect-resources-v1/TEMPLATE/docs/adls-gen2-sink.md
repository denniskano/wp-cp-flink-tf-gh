# Azure Data Lake Storage Gen2 Sink

Lee topics y escribe archivos en ADLS Gen2. Full-managed: clase `AzureDataLakeGen2Sink` (no `AzureBlobStorageSink`). Propiedades `azure.datalake.gen2.*`, no `azure.blob.storage.*`.

- Plantilla: [`../connects/adls-gen2-sink.yaml`](../connects/adls-gen2-sink.yaml)
- Doc oficial: [Azure Data Lake Storage Gen2 Sink Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-datalakeGen2-storage-sink.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`, `BYTES`), `output.data.format` (`AVRO`, `PARQUET`, `JSON`, `BYTES`), `azure.datalake.gen2.account.name`, `partitioner.class`.

`TimeBasedPartitioner` exige `time.interval` (`HOURLY` o `DAILY`). `DefaultPartitioner` agrupa por partición del topic.

Vault: `azure.datalake.gen2.access.key`.

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

Exactly-once vale con partitioner determinista y **sin** WORM en el container. `rotate.schedule.interval.ms` lo invalida.

## Tuning

El archivo se cierra por la primera condición que se cumpla: `flush.size`, `rotate.interval.ms` o `rotate.schedule.interval.ms`.

| Propiedad | Default | Para qué |
|---|---|---|
| `partitioner.class` | — | `DefaultPartitioner` (por partición Kafka) o `TimeBasedPartitioner` (hora/día). |
| `flush.size` | `1000` | Records por archivo. Mínimo 1000 en no Dedicated. |
| `time.interval` | — | Solo TimeBased. `HOURLY` cierra al cambiar la hora; `DAILY` al cambiar el día. |
| `path.format` / `topics.dir` | defaults oficiales | Path Hive-style. Ejemplo: `topics.dir=json_logs/hourly` + `time.interval=HOURLY`. |
| `rotate.schedule.interval.ms` | `-1` | Cierre por reloj. Mínimo 600000 ms (10 min) en la doc. **Invalida exactly-once.** |
| `rotate.interval.ms` | = `time.interval` | Cierre por span de timestamp del record. Stream continuo. Mínimo 600000 ms. |
| `tasks.max` | — | Alinealo a particiones. |
| `max.poll.records` / `max.poll.interval.ms` | `500` / `300000` | Igual que Blob: ajustar si el upload a ADLS es el cuello. |

Ejemplo oficial: `flush.size=1000` + Hourly y llegan 500 records entre las 14:00 y las 15:00 → a las 15:00 se sube el archivo de 500 (el borde horario gana al flush).
