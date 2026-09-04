# Plantillas full-managed (Confluent Cloud)

Copiá el YAML a `{CODAPP}/desa/{use-case}/connects/` y el RBAC a `security/`. **No despliegues esta carpeta.** No hace falta instalar nada en la laptop.

El cluster es **Dedicated** + **Private Link**. El destino se alcanza por Egress Private Link Endpoint + DNS (FQDN público, no IP privada). No hay campo de red en el YAML. Event Hubs Source usa `AMQP_WEB_SOCKETS`; Cosmos V2 usa `azure.cosmos.mode.gateway: true`. En Dedicated no aplica el tope de `max.poll.records` 500 ni el `flush.size` mínimo 1000 de Basic/Standard.

Clases y campos según la [doc de Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/index.html) (no el conector self-managed). Credenciales solo en `vault.secrets`.

Cada guía en `docs/` cubre YAML, Vault, RBAC y **tuning** (throughput, batch, poll, rotación, reintentos).

| Archivo | `connector.class` | Guía | Doc oficial |
|---|---|---|---|
| [connects/datagen-source.yaml](connects/datagen-source.yaml) | `DatagenSource` | [docs/datagen-source.md](docs/datagen-source.md) | [Datagen Source](https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html) |
| [connects/postgres-sink.yaml](connects/postgres-sink.yaml) | `PostgresSink` | [docs/postgres-sink.md](docs/postgres-sink.md) | [PostgreSQL Sink](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-sink.html) |
| [connects/sqlserver-sink.yaml](connects/sqlserver-sink.yaml) | `MicrosoftSqlServerSink` | [docs/sqlserver-sink.md](docs/sqlserver-sink.md) | [SQL Server Sink](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-sink.html) |
| [connects/eventhubs-source.yaml](connects/eventhubs-source.yaml) | `AzureEventHubsSource` | [docs/eventhubs-source.md](docs/eventhubs-source.md) | [Azure Event Hubs Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-event-hubs-source.html) |
| [connects/eventhubs-sink.yaml](connects/eventhubs-sink.yaml) | `HttpSinkV2` | [docs/eventhubs-sink.md](docs/eventhubs-sink.md) | [HTTP Sink V2](https://docs.confluent.io/cloud/current/connectors/cc-http-sink-v2.html) · [Send event](https://learn.microsoft.com/en-us/rest/api/eventhub/send-event) |
| [connects/azure-blob-sink.yaml](connects/azure-blob-sink.yaml) | `AzureBlobSink` | [docs/azure-blob-sink.md](docs/azure-blob-sink.md) | [Azure Blob Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-sink/cc-azure-blob-sink.html) |
| [connects/adls-gen2-sink.yaml](connects/adls-gen2-sink.yaml) | `AzureDataLakeGen2Sink` | [docs/adls-gen2-sink.md](docs/adls-gen2-sink.md) | [ADLS Gen2 Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-datalakeGen2-storage-sink.html) |
| [connects/cosmos-sink.yaml](connects/cosmos-sink.yaml) | `CosmosDbSinkV2` | [docs/cosmos-sink.md](docs/cosmos-sink.md) | [Azure Cosmos DB Sink V2](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-sink-v2.html) |
| [connects/ibmmq-source.yaml](connects/ibmmq-source.yaml) | `IbmMQSource` | [docs/ibmmq-source.md](docs/ibmmq-source.md) | [IBM MQ Source](https://docs.confluent.io/cloud/current/connectors/cc-ibmmq-source.html) |
| [connects/ibmmq-sink.yaml](connects/ibmmq-sink.yaml) | `IbmMQSink` | [docs/ibmmq-sink.md](docs/ibmmq-sink.md) | [IBM MQ Sink](https://docs.confluent.io/cloud/current/connectors/cc-ibm-mq-sink.html) |
| [connects/salesforce-platform-event-sink.yaml](connects/salesforce-platform-event-sink.yaml) | `SalesforcePlatformEventSink` | [docs/salesforce-platform-event-sink.md](docs/salesforce-platform-event-sink.md) | [Salesforce Platform Event Sink](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-platform-event-sink.html) |
| [connects/postgres-source.yaml](connects/postgres-source.yaml) | `PostgresSource` | [docs/postgres-source.md](docs/postgres-source.md) | [PostgreSQL Source](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-source.html) |
| [connects/sqlserver-source.yaml](connects/sqlserver-source.yaml) | `MicrosoftSqlServerSource` | [docs/sqlserver-source.md](docs/sqlserver-source.md) | [SQL Server Source](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source.html) |
| [connects/mysql-sink.yaml](connects/mysql-sink.yaml) | `MySqlSink` | [docs/mysql-sink.md](docs/mysql-sink.md) | [MySQL Sink](https://docs.confluent.io/cloud/current/connectors/cc-mysql-sink.html) |
| [connects/mongodb-atlas-sink.yaml](connects/mongodb-atlas-sink.yaml) | `MongoDbAtlasSink` | [docs/mongodb-atlas-sink.md](docs/mongodb-atlas-sink.md) | [MongoDB Atlas Sink](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink/cc-mongo-db-sink.html) |
| [connects/snowflake-sink.yaml](connects/snowflake-sink.yaml) | `SnowflakeSink` | [docs/snowflake-sink.md](docs/snowflake-sink.md) | [Snowflake Sink](https://docs.confluent.io/cloud/current/connectors/cc-snowflake-sink.html) |
| [connects/servicebus-source.yaml](connects/servicebus-source.yaml) | `AzureServiceBusSource` | [docs/servicebus-source.md](docs/servicebus-source.md) | [Azure Service Bus Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-service-bus-source.html) |
| [connects/azure-functions-sink.yaml](connects/azure-functions-sink.yaml) | `AzureFunctionsSink` | [docs/azure-functions-sink.md](docs/azure-functions-sink.md) | [Azure Functions Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-functions-sink.html) |
| [connects/http-source.yaml](connects/http-source.yaml) | `HttpSourceV2` | [docs/http-source.md](docs/http-source.md) | [HTTP Source V2](https://docs.confluent.io/cloud/current/connectors/cc-http-source-v2.html) |
| [connects/cosmos-source.yaml](connects/cosmos-source.yaml) | `CosmosDbSourceV2` | [docs/cosmos-source.md](docs/cosmos-source.md) | [Azure Cosmos DB Source V2](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-source-v2.html) |
| [connects/azure-blob-source.yaml](connects/azure-blob-source.yaml) | `AzureBlobSource` | [docs/azure-blob-source.md](docs/azure-blob-source.md) | [Azure Blob Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-source.html) |
| [connects/salesforce-cdc-source.yaml](connects/salesforce-cdc-source.yaml) | `SalesforceCdcSource` | [docs/salesforce-cdc-source.md](docs/salesforce-cdc-source.md) | [Salesforce CDC Source](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-source-cdc.html) |

`quickstart` y `schema.string` en Datagen son excluyentes. En Salesforce el evento termina en `__e` y `salesforce.platform.event.num` va de 1 a 5. En ADLS, `time.interval` es obligatorio si `partitioner.class` es `TimeBasedPartitioner`. Event Hubs sink: Confluent Cloud no publica `AzureEventHubsSink`; la plantilla usa `HttpSinkV2` contra la REST Send Event. Cosmos: usá `CosmosDbSinkV2` / `CosmosDbSourceV2` (V1 deprecado). `topicMap` es `topic#container`. JDBC source: `topic.prefix` + `table.include.list` (no `topics`). HTTP Source: `api1.topics`. Blob Source: `topic.regex.list` (`topic:regex`).

Source: write en topic + subject `{topic}-value`. Sink: read en topic + subject, write/read en `{topic}-dlq` si hay `errors.tolerance`, y `group` PREFIXED `connect-lcc-`.

Reemplazá host, topic, SA y paths de Vault. El topic, el schema y el SA tienen que existir antes del apply.
