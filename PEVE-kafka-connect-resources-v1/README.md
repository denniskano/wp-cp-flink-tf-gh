# Conectores Kafka Connect

Aquí se declaran los conectores full-managed y el RBAC del service account. Un archivo por conector.

Antes de desplegar, el **topic**, el **schema** y el **SA** ya tienen que existir. Este repo no los crea.

El cluster Kafka es **Dedicated** con red **Private Link**. El conector sale por un **Egress Private Link Endpoint** + DNS record de esa red (Connection type: Private Link Access). Eso no va en el YAML: el host o la URL siguen siendo el **FQDN público** del servicio (`*.postgres.database.azure.com`, `*.database.windows.net`, namespace, account). No pongas la IP del PE. El EAP y el DNS tienen que estar Ready **antes** del apply. TLS / `ssl.mode: require` se quedan: Private Link es L4.

Salesforce, Snowflake y Mongo Atlas no entran porque el cluster sea PL: cada uno necesita su Private Connect / EAP, o quedan por internet. Datagen no sale a un sistema externo.

## Carpetas

```
{CODAPP}/
  desa|cert|prod/
    smt.yaml                 # opcional; Custom SMT del environment
    {use-case}/
      connects/*.yaml
      security/*.yaml
```

`CODAPP` es la carpeta de tu aplicación (ej. `PEVE`). `use-case` es el nombre que vas a pasar al pipeline.

`smt.yaml` es **por aplicación y ambiente**, no por use-case: el artifact (`ca-…`) es del environment. Plantilla: `TEMPLATE/smt.yaml`. Guía: [TEMPLATE/docs/smt.md](TEMPLATE/docs/smt.md). Si no usas SMT custom, no lo crees.

Solo `*.yaml` (no `*.yml`) y sin subcarpetas dentro de `connects/` o `security/`.

Plantillas para copiar: `TEMPLATE/connects/`. No las despliegues; cópialas a tu `{CODAPP}/desa/{use-case}/`. Ejemplo listo: `PEVE/desa/use-case-name-02/`. SMT de PEVE: `PEVE/desa/smt.yaml`.

En la laptop **no instales nada** (ni Python, ni Node, ni extensiones). Copia el YAML, edita host/topic/SA/Vault y envía el PR. El pipeline aplica.

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
- SMT nativo de Confluent (Cast, Mask, HoistField, etc.): `transforms` + `transforms.<alias>.type` con la clase de Kafka Connect. No uses `custom.smt.artifact.id`.
- **Custom SMT** (JAR propio): además del FQCN, el conector necesita el id del artifact (`ca-…`). Ver abajo.

El nombre del **archivo** (sin `.yaml`) identifica al conector. Si lo renombras o cambias `name`, se recrea y se pierden offsets.

`security/*.yaml`: un `principal` por SA. `resource_type` = `topic` | `subject` | `group` | `transactional-id`. En un sink el consumer group es PREFIXED `connect-lcc-`.

`status` del YAML es el que queda después de un apply. Pause/resume del pipeline es temporal; el apply siguiente vuelve al YAML.

## Custom SMT (JAR propio)

Confluent no busca el JAR por el `name` de `smt.yaml`. Después de subirlo al environment le asigna un id (`ca-…`) y **ese** es el que va en el conector.

1. Declara el JAR en `{CODAPP}/{desa|cert|prod}/smt.yaml` (`name` + `url` de Artifactory). Guía: [TEMPLATE/docs/smt.md](TEMPLATE/docs/smt.md). Ejemplo: `PEVE/desa/smt.yaml`.
2. Sube el artifact con **`deploy-connect-plugins`** (`plan` / `apply`, input `CODAPP`). Terraform imprime:

```text
artifact_ids = {
  "peve-kafka-transformer" = "ca-abc123"
}
```

3. Copia ese `ca-abc123` al YAML del **conector** (`connects/`), no a `smt.yaml`:

```yaml
config_nonsensitive:
  transforms: mySmt
  transforms.mySmt.type: com.bcp.peve.kafka.connect.smt.BytesToAvroAuditWithSchemaParser$Value
  transforms.mySmt.custom.smt.artifact.id: ca-abc123
```

4. Recién ahí aplica el conector (`deploy-kafka-connect`). El artifact tiene que existir **antes**. Si el conector referencia un `ca-…` que no está, queda Failed.

El `name` de `smt.yaml` es solo la etiqueta (y el `display_name` en la UI). No lo pongas en `custom.smt.artifact.id`.

Las siguientes veces, si no cambias el `name` del artifact, el `ca-…` se mantiene: no hay que volver a pegarlo. Si lo renombras o lo borras, Confluent crea otro id y hay que actualizar el conector.

Si no usas JAR propio, no crees `smt.yaml` y no pongas `custom.smt.artifact.id`.

## Desplegar

1. Deja el YAML en la rama del ambiente (PR + merge).
2. Ejecuta el workflow del ambiente:

| Ambiente | Workflow | Carpeta | Rama del YAML |
|---|---|---|---|
| DES | `deploy-kafka-connect` | `desa/` | `develop` |
| CERT | `deploy-kafka-connect-cert` | `cert/` | `release-v2` |
| PROD | `deploy-kafka-connect-prod` | `prod/` | `master` |

| Input | Ejemplo |
|---|---|
| `action` | `plan` primero; `apply` cuando el plan cierre. También `pause`, `resume`. No hay `destroy`. En cert/prod el default es `plan`. |
| `CODAPP` | `PEVE` (la carpeta de tu app) |
| `use_case` | `use-case-name-02` (la carpeta bajo `desa/` / `cert/` / `prod/`) |
| `connector` | solo en pause/resume: nombre del archivo sin `.yaml` |

`plan` / `apply` cubren **todo** el use-case. `pause` / `resume` un conector. No hay `destroy` en el workflow.

Si el conector usa Custom SMT, el artifact (`ca-…`) tiene que existir en ese environment **antes**. En DES: `deploy-connect-plugins` y después `deploy-kafka-connect`. cert/prod de plugins todavía no.
