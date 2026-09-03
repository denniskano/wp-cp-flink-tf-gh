# Azure Service Bus Source

Lee una cola o topic de Azure Service Bus y produce a un topic de Kafka. Full-managed: clase `AzureServiceBusSource`.

- Plantilla: [`../connects/servicebus-source.yaml`](../connects/servicebus-source.yaml)
- Doc oficial: [Azure Service Bus Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-azure-service-bus-source.html)

## YAML

Obligatorios: `kafka.topic`, `output.data.format`, `azure.servicebus.namespace`, `azure.servicebus.entity.name`.

`azure.servicebus.namespace` es **solo** el nombre (`sbns-app-des`), no el FQDN `*.servicebus.windows.net`.

Si la entity es un **topic** de Service Bus, hace falta `azure.servicebus.subscription`. En cola, no.

Vault: `azure.servicebus.sas.keyname` y `azure.servicebus.sas.key`. La policy necesita Listen.

El SA: **write** en el topic y en `{topic}-value`.

El cluster es Dedicated + Private Link. El namespace es el nombre corto; el EAP + DNS (`*.servicebus.windows.net`) resuelven al PE.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `tasks.max` | — | Más tasks = más consumidores en paralelo. En cola, coordiná con el prefetch de Service Bus; no compartas la misma subscription con otra app. |
| `producer.override.linger.ms` | — | Agrupa writes a Kafka si Service Bus entrega de a poco. |
| `producer.override.compression.type` | — | Compresión hacia Kafka. |

La SAS y la subscription no se comparten con otro consumer: el conector avanza el lock/complete. Si recreás el conector se pierden offsets del lado Kafka; los mensajes no completados vuelven a la cola/subscription según el lock de Service Bus.
