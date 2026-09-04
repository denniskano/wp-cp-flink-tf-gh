# Azure Cosmos DB Sink V2

Escribe topics de Kafka en containers de Azure Cosmos DB (NoSQL). Full-managed: clase `CosmosDbSinkV2`. El sink V1 está **deprecado** (EOL 6-abr-2027); no uses esa clase.

- Plantilla: [`../connects/cosmos-sink.yaml`](../connects/cosmos-sink.yaml)
- Doc oficial: [Azure Cosmos DB Sink V2 Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-sink-v2.html)

## YAML

Obligatorios: `topics`, `input.data.format` (`AVRO`, `JSON_SR`, `PROTOBUF`, `JSON`), `azure.cosmos.account.endpoint` (`https://…documents.azure.com:443/`), `azure.cosmos.sink.database.name`, `azure.cosmos.sink.containers.topicMap`.

`topicMap` es 1:1 `topic#container`, varios separados por coma: `t1#c1,t2#c2`.

`id` en Cosmos es **minúscula**. Estrategia (`azure.cosmos.sink.id.strategy`, default `FullKeyStrategy`):

| Estrategia | `id` del documento |
|---|---|
| `FullKeyStrategy` | key del record Kafka |
| `KafkaMetadataStrategy` | `{topic}-{partition}-{offset}` |
| `ProvidedInKeyStrategy` / `ProvidedInValueStrategy` | campo `id` en el key/value |
| `TemplateStrategy` | template que defines |

Auth:

| `azure.cosmos.auth.type` | Vault |
|---|---|
| `MasterKey` (plantilla / ejemplo CLI) | `azure.cosmos.account.key` |
| `ServicePrincipal` / `SERVICE_PRINCIPAL` (recomendado en prod) | `azure.cosmos.auth.aad.clientId`, `azure.cosmos.auth.aad.clientSecret` + `azure.cosmos.account.tenantId`. Rol **Cosmos DB Built-in Data Contributor**. |

El SA: **read** topic + subject, DLQ si hay `errors.tolerance`, `group` PREFIXED `connect-lcc-`.

Coloca el cluster Kafka y Cosmos en la **misma región** e indica esa región en `azure.cosmos.preferredRegionList`.

El cluster es Dedicated + Private Link. El endpoint sigue siendo `https://…documents.azure.com:443/`. Configura `azure.cosmos.mode.gateway: true`: Direct abre muchos puertos/IPs que el PE no cubre. Sub-recurso del EAP: `Sql` (NoSQL).

## Tuning

V2 escribe en **bulk** (mejor que V1). El cuello de botella suele ser los RU de Cosmos, no Kafka.

| Propiedad | Default | Para qué |
|---|---|---|
| `azure.cosmos.sink.bulk.enabled` | `true` | Mantén `true`. Single-doc es más lento. |
| `azure.cosmos.sink.bulk.initialBatchSize` | `1` | Micro-batch inicial. El conector lo ajusta según throttle. Reduce el valor si el arranque consume muchos RU. |
| `azure.cosmos.sink.bulk.maxConcurrentCosmosPartitions` | `-1` (todas) | En containers con cientos de particiones físicas, limítalo si cada batch no cubre todas. |
| `azure.cosmos.sink.write.strategy` | `ItemOverwrite` | `ItemOverwrite` = upsert. `ItemAppend` = create (ignora conflicto). `ItemDelete*` borra. `ItemPatch` = update parcial. |
| `azure.cosmos.sink.maxRetryCount` | `10` | Reintentos ante error transitorio de write. |
| `azure.cosmos.sink.errors.tolerance.level` | `None` | `All` registra el error y continúa después de los retries. Distinto de `errors.tolerance` (DLQ de Connect). |
| `azure.cosmos.throughputControl.enabled` | `false` | Configura `true` + `targetThroughput` / `targetThroughputThreshold` para no agotar los RU del container. |
| `azure.cosmos.mode.gateway` | `false` | En esta red: `true` (gateway). Direct no pasa por Private Link. |
| `tasks.max` | — | Más tasks = más writes en paralelo. Aumenta los RU o activa autoscale si ves 429. |
| `max.poll.records` / `max.poll.interval.ms` | `500` / `300000` | Reduce `max.poll.records` si Cosmos aplica throttle; aumenta `max.poll.interval.ms` si el bulk tarda. |

Si migras de V1, deja `azure.cosmos.sink.id.strategy: FullKeyStrategy` (default) para no romper ids. El database y el container tienen que existir; el conector no los crea.
