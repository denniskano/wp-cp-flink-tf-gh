# Pedir Private Link (equipo de aplicación)

Modelo del banco: **un Private Endpoint por entorno** (`dev` | `cert` | `prod`), no por aplicación ni por namespace. En prod HA, **un PE por región** del par. Las **connectivity rules** sí son por namespace: cada YAML pega el **mismo** ID.

1. Ticket a **Cloud Governance**: Temporal Cloud, **entorno**, regiones del YAML (prod = las dos), account Temporal. No un PE por CODAPP.
2. Ellos crean el PE / VPC Endpoint / PSC (una vez por env/región) y te devuelven el ID.
3. Lo pegas en `connectivity[]` de **cada** namespace de ese env:
   - Azure: `azure_pe_resource_id` (ARM)
   - AWS: `connection_id` (`vpce-…`)
   - GCP: `connection_id` + `gcp_project_id`
4. Corres el workflow de Temporal (`deploy-temporal-{dev|cert|prod}`).

El IAC no crea el PE. Campos del YAML: [NAMESPACE.md](NAMESPACE.md). Guía larga: `PEVE-orchestration-automation/docs/PRIVATELINK.md`.
