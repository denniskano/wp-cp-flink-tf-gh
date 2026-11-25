# Cómo llega el worker a Temporal: internet o Private Endpoint

Hay **dos caminos**. Auth (API key o mTLS) es **independiente** de la red: la elegís en el YAML del namespace. Esto solo es **por dónde sale el tráfico**.

| | **A. Internet (sin PE)** | **B. Private Endpoint** |
|---|---|---|
| Cuándo | Ahora: todavía no hay PE | Cuando Governance entregue el endpoint |
| YAML | **No** pongas `connectivity` | `type: private` + ID del PE |
| Red del worker | Egress a `*.tmprl.cloud:7233` (público) | VNet del banco → PE → Temporal (sin internet) |
| Quién crea la red | Nadie extra | Cloud Governance (una vez por **entorno**) |

PE = **Private Endpoint** de Azure (ficha en la VNet). En AWS es VPC Endpoint (`vpce-…`); en GCP, Private Service Connect.

El IAC **no** crea el PE. Terraform solo crea la *connectivity rule* de Temporal si el YAML trae `connectivity`.

Campos: [NAMESPACE.md](NAMESPACE.md#connectivity). Guía Governance/DNS HA: `PEVE-orchestration-automation/docs/PRIVATELINK.md`.

---

## A. Ir por internet (sin PE)

Es el camino **actual**. El namespace queda alcanzable en la API pública de Temporal Cloud (sigue pidiendo API key o certificado).

### Qué hacer

1. En `{CODAPP}/{dev|cert|prod}/namespaces/*.yaml` **no** declares `connectivity`. No uses `type: private` sin el ID del PE.
2. Auth: `api_key_auth: true` (default) o mTLS con CA en Vault. Ver [NAMESPACE.md](NAMESPACE.md#auth-api-key-o-mtls).
3. PR + workflow `deploy-temporal-{dev|cert|prod}` (`plan` y luego `apply`).
4. Worker / client SDK:
   - Host: Namespace Endpoint `\<namespace\>.\<cuenta\>.tmprl.cloud:7233` (el apply / consola Temporal lo muestran).
   - La red de la app tiene que **salir a internet** a ese FQDN, puerto **7233** (y 443 si usan la UI).
   - API key: la del SA en Vault `{env}/{codapp}/temporal/apikeys/{display_name}`.
   - mTLS: client cert + `mtls_grpc_address`.

### Qué no hacer

- No pongas `type: private` “por si acaso”: el CI exige el ID del PE y Temporal no va a enrutar por PrivateLink.
- No hace falta `type: public`. Omitir el bloque es el camino público.

Prod **sin PE** igual lleva **2 regiones** en el YAML: eso es réplica HA de Temporal, no PrivateLink.

---

## B. Ir por Private Endpoint

El worker **no** sale a internet hacia Temporal: habla con un PE en la VNet. Modelo banco: **un PE por entorno** (`dev` | `cert` | `prod`), no por aplicación ni por namespace. En prod HA, **un PE por región** del par (ej. Azure + AWS). Las **rules** sí son por namespace: todos los YAML del env pegan el **mismo** ID.

### Qué hacer (app)

1. Ticket a **Cloud Governance**: Temporal Cloud Private Link, **entorno**, regiones del YAML (prod = las dos), account Temporal. **No** un PE por CODAPP.
2. Governance pide a Temporal Dev Success el alias de Private Link (Azure: por cuenta). Crea el PE / VPC Endpoint / PSC y te devuelve:
   - Azure: `azure_pe_resource_id` (ARM)
   - AWS: `connection_id` (`vpce-…`)
   - GCP: `connection_id` + `gcp_project_id`
3. En **cada** namespace de ese env: el **mismo** ID de PE, pero un `connectivity.name` **distinto** (el CI no permite el mismo `name` dos veces en el env):

```yaml
# peve-dev.yaml
connectivity:
  - name: peve-dev-pl-centralus
    type: private
    region: azure-centralus
    azure_pe_resource_id: "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateEndpoints/<pe-del-entorno>"
```

```yaml
# peve-dev-pagos.yaml — mismo ARM, otro name
connectivity:
  - name: peve-dev-pagos-pl-centralus
    type: private
    region: azure-centralus
    azure_pe_resource_id: "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/privateEndpoints/<pe-del-entorno>"
```

Prod HA con PE, **una entrada por región**:

```yaml
connectivity:
  - name: peve-prod-pl-centralus
    type: private
    region: azure-centralus
    azure_pe_resource_id: "/subscriptions/…/privateEndpoints/<pe-azure>"
  - name: peve-prod-pl-use1
    type: private
    region: aws-us-east-1
    connection_id: "vpce-…"
```

4. Workflow `deploy-temporal-*` `apply`. Terraform crea la connectivity rule y la pega al namespace.
5. Worker:
   - Sigue usando el **Namespace Endpoint** (`….tmprl.cloud:7233`), no una IP suelta.
   - DNS **privado** (lo documenta Governance): override de `*.region.tmprl.cloud` → PE. **No** overrides el hostname del namespace (si no, el failover HA no sigue el CNAME).
   - Auth igual que en A (API key o mTLS).
   - El pod/VM tiene que **llegar al PE** (NSG, UDR). Ya no hace falta egress público a Temporal.

### Qué no hacer

- Un PE por CODAPP o por namespace.
- IDs de mentira (`0000…`, `vpce-000…`): el CI los deja pasar; Temporal no.
- En HA, pinnear el SDK a una sola Regional Endpoint si quieres failover automático.

---

## Pasar de internet (A) a PE (B)

1. Governance entrega el ID.
2. Agregás `connectivity` en todos los YAML del env: **mismo ID de PE**, `name` de rule distinto por namespace.
3. `plan` / `apply`.
4. Coordiná con Networking el DNS privado **antes** de cortar el egress público.
5. Probá el worker contra el Namespace Endpoint (debe resolver al PE). Recién ahí cerrás internet a Temporal.

## Volver de PE (B) a internet (A)

1. El worker tiene que poder salir a `*.tmprl.cloud:7233` otra vez.
2. Sacás `connectivity` del YAML (todos los namespaces del env).
3. `apply`. Terraform deja de adjuntar rules.
4. No borres el PE en Azure hasta que Governance lo apague; este IAC no lo destruye.
