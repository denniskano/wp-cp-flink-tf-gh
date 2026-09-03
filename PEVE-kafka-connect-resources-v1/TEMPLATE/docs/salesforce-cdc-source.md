# Salesforce CDC Source

Lee Change Data Capture de Salesforce y produce a un topic. Full-managed: clase `SalesforceCdcSource`. Es el source CDC clásico más usado; Confluent está migrando casos nuevos a **Salesforce Source V2** ([doc](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-source-v2.html)) — esta plantilla cubre CDC V1 porque sigue en el catálogo y en la mayoría de los stacks.

- Plantilla: [`../connects/salesforce-cdc-source.yaml`](../connects/salesforce-cdc-source.yaml)
- Doc oficial: [Salesforce CDC Source Connector for Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/cc-salesforce-source-cdc.html)

## YAML

Obligatorios: `kafka.topic`, `output.data.format`, `salesforce.grant.type`, `salesforce.instance`, `salesforce.cdc.name` (ej. `AccountChangeEvent`; case sensitive).

Grant y secretos de Vault (igual que el Platform Event Sink):

| `salesforce.grant.type` | Secretos |
|---|---|
| `PASSWORD` (default de la plantilla) | `salesforce.username`, `salesforce.password`, `salesforce.password.token`, `salesforce.consumer.key`, `salesforce.consumer.secret` |
| `CLIENT_CREDENTIALS` | `salesforce.consumer.key`, `salesforce.consumer.secret`. `salesforce.instance` = My Domain (no `login.salesforce.com`). |
| `JWT_BEARER` | `salesforce.username`, `salesforce.consumer.key`, `salesforce.jwt.keystore.file`, `salesforce.jwt.keystore.password` |

Confluent depreca `PASSWORD` el **15-sep-2026**. Para algo que vaya a vivir, usá `CLIENT_CREDENTIALS` o `JWT_BEARER`.

El SA: **write** en el topic y `{topic}-value`.

El Private Link del cluster Dedicated **no** alcanza Salesforce. `salesforce.instance` sale por internet salvo Private Connect / EAP propio.

En Salesforce: CDC habilitado en el objeto, usuario con API Enabled y permiso de listen del canal.

## Tuning

| Propiedad | Default | Para qué |
|---|---|---|
| `tasks.max` | — | Suele ser 1 (un canal CDC). Más tasks no multiplican el replay de Salesforce. |
| `request.max.retries.time.ms` | — | Ventana de reintento ante blips de Streaming API. |
| `connection.timeout` | — | Timeout del endpoint Streaming. |
| `salesforce.initial.start` | — | Desde dónde arranca si no hay offset (`latest` vs replay). No lo cambies después del primer apply. |

Si recreás el conector se pierde el Replay ID: puede re-emitir o saltear según `initial.start`. Los límites de eventos/día de Salesforce aplican igual que a cualquier subscriber CDC.
