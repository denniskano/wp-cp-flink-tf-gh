# Private connectivity (lo crea Cloud Governance)

Este IAC **no** crea el Private Endpoint. La app elige el camino en el YAML:

| Camino | YAML | Qué hace Terraform |
|---|---|---|
| **Internet** | Sin `connectivity` | No crea rules (`connectivity_rule_ids` se omite; no se manda `[]`) |
| **Private Endpoint** | `type: private` + ID | `temporalcloud_connectivity_rule` + attach al namespace |

Pasos para el equipo de aplicación (worker, DNS, pasar de A a B): **`PEVE-orchestration-resources/docs/PRIVATELINK.md`**.

## Si van por PE (Governance)

1. Ticket a Cloud Governance: Temporal Cloud Private Link, **entorno** (`dev|cert|prod`), cloud/región de cada réplica, account Temporal. **Un PE por entorno** (prod HA: uno por región), no por aplicación. Las rules del YAML sí son por namespace (mismo ID de PE).
2. Governance pide a Temporal Dev Success el **Private Link Service Alias** (Azure: es por cuenta, no público). AWS usa el service `com.amazonaws.vpce.<region>.vpce-svc-…` de la [doc de regiones](https://docs.temporal.io/evaluate/cloud/regions).
3. Governance crea:
   - **Azure:** Private Endpoint (`blob` no aplica; es el PE hacia Temporal) y entrega `azure_pe_resource_id` ARM.
   - **AWS:** VPC Endpoint y entrega `connection_id` (`vpce-…`).
   - **GCP:** PSC y entrega `connection_id` + `gcp_project_id`.
4. Prod HA: **un PE por región** del par (si el par es Azure+AWS, hay PE en las dos nubes).
5. Pegar los IDs en `{CODAPP}/{env}/namespaces/*.yaml` → `connectivity[]`.
6. DNS privado (Workers/Clients) lo documenta Governance; no override del Namespace Endpoint global en HA (usar override **regional**). Ver [HA connectivity](https://docs.temporal.io/cloud/high-availability/ha-connectivity).
7. Workflow Temporal `apply`.

Sin bloque `connectivity` el CI pasa (camino internet). Si `type: private` y falta el ID, `validate-temporal-yaml.sh` falla.
