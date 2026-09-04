# Azure Event Hubs Source

Lee un Event Hub y produce a un topic de Kafka. Full-managed: clase `AzureEventHubsSource`.

- Plantilla: [`../connects/eventhubs-source.yaml`](../connects/eventhubs-source.yaml)
- Doc oficial: [Azure Event Hubs Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-event-hubs-source.html)

## YAML

Obligatorios: `kafka.topic`, `output.data.format`, `azure.eventhubs.namespace`, `azure.eventhubs.hub.name`, `azure.eventhubs.consumer.group`.

Vault (auth SAS): `azure.eventhubs.sas.keyname` y `azure.eventhubs.sas.key`. La policy necesita Listen en el hub.

El SA: **write** en el topic y en `{topic}-value`.

`azure.eventhubs.partition.starting.position`: `START_OF_STREAM` (replay desde el inicio si no hay offset) o `END_OF_STREAM` (solo nuevo). Solo aplica si no hay offsets guardados.

`azure.eventhubs.transport.type`: en Dedicated + Private Link usa `AMQP_WEB_SOCKETS` (443). `AMQP` (TCP 5671) suele no pasar por el PE. El namespace es el nombre corto (`ehns-app-des`); el EAP resuelve `*.servicebus.windows.net`.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `max.events` | `50` | Eventos por poll y por partición del hub. Máximo 499. Auméntalo si hay retraso y el hub tiene mucho backlog. |
| `tasks.max` | — | Ideal: 1 task por partición del Event Hub. Más tasks que particiones no mejoran el throughput. |
| `azure.eventhubs.offset.type` | `OFFSET` | `OFFSET` (offset de Event Hubs) o `SEQ_NUM`. No lo cambies después del primer apply. |
| `producer.override.linger.ms` | — | Agrupa writes a Kafka si el hub entrega en pequeños lotes. |
| `producer.override.compression.type` | — | Compresión hacia Kafka. |

El consumer group del hub (`$Default` o uno propio) no lo compartas con otra app: el conector avanza el checkpoint. Si recreas el conector (cambio de `name` o del archivo YAML) se pierden offsets y `starting.position` vuelve a aplicar.
