# Azure Cosmos DB Source V2

Lee el change feed de Cosmos DB (NoSQL) y produce a Kafka. Full-managed: clase `CosmosDbSourceV2`.

- Plantilla: [`../connects/cosmos-source.yaml`](../connects/cosmos-source.yaml)
- Doc oficial: [Azure Cosmos DB Source V2 Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-cosmos-source-v2.html)

## YAML

Obligatorios: `output.data.format`, `azure.cosmos.account.endpoint` (`https://…documents.azure.com:443/`), `azure.cosmos.source.database.name`, `azure.cosmos.source.containers.topicMap`.

`topicMap` es 1:1 `topic#container`, varios separados por coma: `t1#c1,t2#c2`. No uses `topics` ni `kafka.topic`.

`azure.cosmos.source.containers.includeAll` + `includedList`: si `includeAll` es `false`, listá los containers.

Auth (igual que el sink V2):

| Tipo | Vault |
|---|---|
| MasterKey (plantilla) | `azure.cosmos.account.key` |
| Service Principal (recomendado en prod) | client id/secret + tenant. Rol de lectura en el account. |

El SA: **write** en cada topic del `topicMap` y `{topic}-value`.

Colocá Kafka y Cosmos en la **misma región** y poné esa región en `azure.cosmos.preferredRegionList`.

El cluster es Dedicated + Private Link. Endpoint FQDN público. `azure.cosmos.mode.gateway: true` (Direct no pasa por el PE). Sub-recurso del EAP: `Sql`.

## Tuning

El change feed es incremental. El cuello suele ser RUs de Cosmos.

| Propiedad | Default | Para qué |
|---|---|---|
| `azure.cosmos.preferredRegionList` | — | Región de lectura. Desalinearla suma latencia y RU cruzados. |
| `azure.cosmos.throughputControl.enabled` | `false` | `true` + target RU para no comerse el container. |
| `azure.cosmos.mode.gateway` | `false` | En esta red: `true` (gateway). Direct no pasa por Private Link. |
| `tasks.max` | — | Más tasks = más lecturas en paralelo del feed. Subí RU si ves 429. |

Si recreás el conector se pierde el lease/checkpoint del change feed: puede re-emitir desde el inicio del feed (duplicados). El database y el container tienen que existir.
