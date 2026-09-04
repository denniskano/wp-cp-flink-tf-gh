# Conectores Kafka Connect

Acá se declaran los conectores full-managed y el RBAC del service account. Un archivo por conector.

Antes de desplegar, el **topic**, el **schema** y el **SA** ya tienen que existir. Este repo no los crea.

El cluster Kafka es **Dedicated** con red **Private Link**. El conector sale por un **Egress Private Link Endpoint** + DNS record de esa red (Connection type: Private Link Access). Eso no va en el YAML: el host o la URL siguen siendo el **FQDN público** del servicio (`*.postgres.database.azure.com`, `*.database.windows.net`, namespace, account). No pongas la IP del PE. El EAP y el DNS tienen que estar Ready **antes** del apply. TLS / `ssl.mode: require` se quedan: Private Link es L4.

Salesforce, Snowflake y Mongo Atlas no entran porque el cluster sea PL: cada uno necesita su Private Connect / EAP, o quedan por internet. Datagen no sale a un sistema externo.

## Carpetas

```
{CODAPP}/
  desa|cert|prod/
    {use-case}/
      connects/*.yaml
      security/*.yaml
```

`CODAPP` es la carpeta de tu aplicación (ej. `PEVE`). `use-case` es el nombre que vas a pasar al pipeline.

Solo `*.yaml` (no `*.yml`) y sin subcarpetas dentro de `connects/` o `security/`.

Plantillas para copiar: `TEMPLATE/connects/`. No las despliegues; copialas a tu `{CODAPP}/desa/{use-case}/`. Ejemplo armado: `PEVE/desa/use-case-name-02/`.

En la laptop **no instales nada** (ni Python, ni Node, ni extensiones). Copiá el YAML, editá host/topic/SA/Vault y mandá el PR. El pipeline aplica.

## Conectores (referencia)

Guía local (YAML, RBAC, tuning) y documentación oficial de Confluent Cloud. Clases y propiedades son las del conector **full-managed**, no self-managed.

| Conector | `connector.class` | Guía (tuning) | Doc oficial |
|---|---|---|---|
| Datagen Source | `DatagenSource` | [TEMPLATE/docs/datagen-source.md](TEMPLATE/docs/datagen-source.md) | [Datagen Source](https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html) |
| PostgreSQL Sink | `PostgresSink` | [TEMPLATE/docs/postgres-sink.md](TEMPLATE/docs/postgres-sink.md) | [PostgreSQL Sink](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-sink.html) |
| SQL Server Sink | `MicrosoftSqlServerSink` | [TEMPLATE/docs/sqlserver-sink.md](TEMPLATE/docs/sqlserver-sink.md) | [Microsoft SQL Server Sink](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-sink.html) |
| Azure Event Hubs Source | `AzureEventHubsSource` | [TEMPLATE/docs/eventhubs-source.md](TEMPLATE/docs/eventhubs-source.md) | [Azure Event Hubs Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-event-hubs-source.html) |
| Azure Event Hubs Sink | `HttpSinkV2` | [TEMPLATE/docs/eventhubs-sink.md](TEMPLATE/docs/eventhubs-sink.md) | [HTTP Sink V2](https://docs.confluent.io/cloud/current/connectors/cc-http-sink-v2.html) · [Send event](https://learn.microsoft.com/en-us/rest/api/eventhub/send-event) |
| Azure Blob Sink | `AzureBlobSink` | [TEMPLATE/docs/azure-blob-sink.md](TEMPLATE/docs/azure-blob-sink.md) | [Azure Blob Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-sink/cc-azure-blob-sink.html) |
| ADLS Gen2 Sink | `AzureDataLakeGen2Sink` | [TEMPLATE/docs/adls-gen2-sink.md](TEMPLATE/docs/adls-gen2-sink.md) | [ADLS Gen2 Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-datalakeGen2-storage-sink.html) |
| Azure Cosmos DB Sink V2 | `CosmosDbSinkV2` | [TEMPLATE/docs/cosmos-sink.md](TEMPLATE/docs/cosmos-sink.md) | [Azure Cosmos DB Sink V2](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-sink-v2.html) |
| IBM MQ Source | `IbmMQSource` | [TEMPLATE/docs/ibmmq-source.md](TEMPLATE/docs/ibmmq-source.md) | [IBM MQ Source](https://docs.confluent.io/cloud/current/connectors/cc-ibmmq-source.html) |
| IBM MQ Sink | `IbmMQSink` | [TEMPLATE/docs/ibmmq-sink.md](TEMPLATE/docs/ibmmq-sink.md) | [IBM MQ Sink](https://docs.confluent.io/cloud/current/connectors/cc-ibm-mq-sink.html) |
| Salesforce Platform Event Sink | `SalesforcePlatformEventSink` | [TEMPLATE/docs/salesforce-platform-event-sink.md](TEMPLATE/docs/salesforce-platform-event-sink.md) | [Salesforce Platform Event Sink](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-platform-event-sink.html) |
| PostgreSQL Source | `PostgresSource` | [TEMPLATE/docs/postgres-source.md](TEMPLATE/docs/postgres-source.md) | [PostgreSQL Source](https://docs.confluent.io/cloud/current/connectors/cc-postgresql-source.html) |
| SQL Server Source | `MicrosoftSqlServerSource` | [TEMPLATE/docs/sqlserver-source.md](TEMPLATE/docs/sqlserver-source.md) | [Microsoft SQL Server Source](https://docs.confluent.io/cloud/current/connectors/cc-microsoft-sql-server-source.html) |
| MySQL Sink | `MySqlSink` | [TEMPLATE/docs/mysql-sink.md](TEMPLATE/docs/mysql-sink.md) | [MySQL Sink](https://docs.confluent.io/cloud/current/connectors/cc-mysql-sink.html) |
| MongoDB Atlas Sink | `MongoDbAtlasSink` | [TEMPLATE/docs/mongodb-atlas-sink.md](TEMPLATE/docs/mongodb-atlas-sink.md) | [MongoDB Atlas Sink](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink/cc-mongo-db-sink.html) |
| Snowflake Sink | `SnowflakeSink` | [TEMPLATE/docs/snowflake-sink.md](TEMPLATE/docs/snowflake-sink.md) | [Snowflake Sink](https://docs.confluent.io/cloud/current/connectors/cc-snowflake-sink.html) |
| Azure Service Bus Source | `AzureServiceBusSource` | [TEMPLATE/docs/servicebus-source.md](TEMPLATE/docs/servicebus-source.md) | [Azure Service Bus Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-service-bus-source.html) |
| Azure Functions Sink | `AzureFunctionsSink` | [TEMPLATE/docs/azure-functions-sink.md](TEMPLATE/docs/azure-functions-sink.md) | [Azure Functions Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-functions-sink.html) |
| HTTP Source V2 | `HttpSourceV2` | [TEMPLATE/docs/http-source.md](TEMPLATE/docs/http-source.md) | [HTTP Source V2](https://docs.confluent.io/cloud/current/connectors/cc-http-source-v2.html) |
| Azure Cosmos DB Source V2 | `CosmosDbSourceV2` | [TEMPLATE/docs/cosmos-source.md](TEMPLATE/docs/cosmos-source.md) | [Azure Cosmos DB Source V2](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-source-v2.html) |
| Azure Blob Source | `AzureBlobSource` | [TEMPLATE/docs/azure-blob-source.md](TEMPLATE/docs/azure-blob-source.md) | [Azure Blob Source](https://docs.confluent.io/cloud/current/connectors/cc-azure-blob-source.html) |
| Salesforce CDC Source | `SalesforceCdcSource` | [TEMPLATE/docs/salesforce-cdc-source.md](TEMPLATE/docs/salesforce-cdc-source.md) | [Salesforce CDC Source](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-source-cdc.html) |

Índice y plantillas: [TEMPLATE/README.md](TEMPLATE/README.md).

## Qué va en el YAML

`connects/<nombre>.yaml`:

- `name` y `status` (`RUNNING` o `PAUSED`).
- `config_nonsensitive.kafka.auth.mode` tiene que ser `SERVICE_ACCOUNT`.
- Topic: `topics` **o** `kafka.topic` (no los dos). JDBC source usa `topic.prefix`; HTTP Source `api1.topics`; Blob Source `topic.regex.list`; Cosmos Source `azure.cosmos.source.containers.topicMap`.
- El SA va en `vault.service_account` (el `display_name` de Confluent).
- Passwords y users: `vault.secrets.<clave>` con `path` y `field` de Vault. No pongas secretos en claro ni un bloque `config_sensitive`.
- Red: no hay campo Private Link en el YAML. Host/URL = FQDN público.

El nombre del **archivo** (sin `.yaml`) identifica al conector. Si lo renombrás o cambiás `name`, se recrea y se pierden offsets.

`security/*.yaml`: un `principal` por SA. `resource_type` = `topic` | `subject` | `group` | `transactional-id`. En un sink el consumer group es PREFIXED `connect-lcc-`.

`status` del YAML es el que queda después de un apply. Pause/resume del pipeline es temporal; el apply siguiente vuelve al YAML.

## Desplegar (DES)

1. Dejá el YAML en `develop` (PR + merge).
2. Corré el workflow **`deploy-kafka-connect`**:

| Input | Ejemplo |
|---|---|
| `action` | `plan` primero; `apply` cuando el plan cierre. También `destroy`, `pause`, `resume` |
| `CODAPP` | `PEVE` (la carpeta de tu app) |
| `use_case` | `use-case-name-02` (la carpeta bajo `desa/`) |
| `connector` | solo en pause/resume: nombre del archivo sin `.yaml` |

Hoy el pipeline apunta a `desa`. cert/prod todavía no.

`plan` / `apply` / `destroy` cubren **todo** el use-case. `pause` / `resume` un conector.
