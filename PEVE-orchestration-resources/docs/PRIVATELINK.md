# Pedir Private Link (equipo de aplicación)

1. Ticket a **Cloud Governance**: Temporal Cloud, CODAPP, env, regiones del YAML (prod = las dos).
2. Ellos crean el PE / VPC Endpoint / PSC y te devuelven el ID.
3. Lo pegas en `connectivity[].azure_pe_resource_id` (Azure), `connection_id` (AWS) o `connection_id` + `gcp_project_id` (GCP).
4. Corres el workflow de Temporal.

El IAC no crea el PE. Guía larga: `PEVE-orchestration-automation/docs/PRIVATELINK.md`.
