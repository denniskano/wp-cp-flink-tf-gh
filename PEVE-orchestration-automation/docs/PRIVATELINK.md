# Private connectivity (lo crea Cloud Governance)

Este IAC **no** crea el Private Endpoint en la VNet del banco. Otro equipo (Cloud Governance) lo provisiona. La app pone el ID resultante en el YAML.

## Pasos para el equipo de aplicación

1. Abrir ticket a Cloud Governance: Temporal Cloud Private Link, **entorno** (`dev|cert|prod`), cloud/región de cada réplica, account Temporal. **Un PE por entorno** (prod HA: uno por región), no por aplicación. Las rules del YAML sí son por namespace (mismo ID de PE).
2. Governance pide a Temporal Dev Success el **Private Link Service Alias** (Azure: es por cuenta, no público). AWS usa el service `com.amazonaws.vpce.<region>.vpce-svc-…` de la [doc de regiones](https://docs.temporal.io/evaluate/cloud/regions).
3. Governance crea:
   - **Azure:** Private Endpoint (`blob` no aplica; es el PE hacia Temporal) y entrega `azure_pe_resource_id` ARM.
   - **AWS:** VPC Endpoint y entrega `connection_id` (`vpce-…`).
   - **GCP:** PSC y entrega `connection_id` + `gcp_project_id`.
4. Prod HA: **un PE por región** del par (si el par es Azure+AWS, hay PE en las dos nubes).
5. Pegar los IDs en `{CODAPP}/{env}/namespaces/*.yaml` → `connectivity[]`.
6. DNS privado (Workers/Clients) lo documenta Governance; no override del Namespace Endpoint global en HA (usar override **regional**). Ver [HA connectivity](https://docs.temporal.io/cloud/high-availability/ha-connectivity).
7. Disparar el workflow Temporal: Terraform crea `temporalcloud_connectivity_rule` y la adjunta al namespace.

Sin el ID en el YAML, `validate-temporal-yaml.sh` falla en `type: private`.
