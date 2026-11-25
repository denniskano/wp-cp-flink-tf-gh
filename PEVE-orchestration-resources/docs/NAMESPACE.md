# Namespace Temporal Cloud (YAML)

Guía para el **equipo de aplicación**. Copiá [`TEMPLATE/namespace.yaml`](../TEMPLATE/namespace.yaml) a `{CODAPP}/{dev|cert|prod}/namespaces/<nombre>.yaml`. El nombre del archivo puede ser cualquiera; Temporal usa el campo `name`.

El CI (`validate-temporal-yaml.sh` en el IAC) y Terraform leen **solo** estos campos. Lo que no esté acá no se aplica.

GHA: `deploy-temporal-dev` | `deploy-temporal-cert` | `deploy-temporal-prod` en `PEVE-eda-workflows-develop-v2`. Input `CODAPP` = carpeta (ej. `PEVE`, mayúsculas).

Nexus (otro archivo): [NEXUS.md](NEXUS.md).  
**Red del worker (internet vs Private Endpoint):** [PRIVATELINK.md](PRIVATELINK.md).

---

## Layout

```
{CODAPP}/                  # 4 caracteres, ej. PEVE
  dev|cert|prod/           # no uses desa
    namespaces/*.yaml      # uno o más namespaces del mismo env
    nexus/*.yaml           # opcional
```

Varios YAML en `namespaces/` = varios namespaces en el **mismo** apply.

---

## Campos raíz

| Campo | Obligatorio | Default | Valores | Qué es |
|---|---|---|---|---|
| `name` | Sí | — | `{codapp}-{dev\|cert\|prod}` o `{codapp}-{env}-{suffix}` | Nombre del namespace en Temporal. Minúsculas. |
| `regions` | Sí | — | 1 código (`dev`/`cert`) o **2** (`prod`). Códigos de la [matriz HA](#regiones) | Dónde vive el namespace. **No se puede cambiar** después de crear (ForceNew). |
| `retention_days` | No | `14` | Entero ≥ 1. En Temporal Cloud suele ser 1–90 | Días de historia de workflows. |
| `api_key_auth` | No | `true` | `true` \| `false` | Cómo se autentican workers/clients al namespace. Ver [Auth](#auth-api-key-o-mtls). |
| `accepted_client_ca_vault` | Si mTLS | — | `{path, field, mount}` | **De dónde** sacar la CA. El PEM vive en Vault, no en git. |
| `certificate_filters` | No | omitir | Lista. Ver [Auth](#auth-api-key-o-mtls) | Restringe qué client certs entran. Requiere CA. |
| `labels` | No | `{}` | Mapa string→string, máx. 10 pares | Tags del namespace en Temporal. Preferí `labels`. |
| `tags` | No | `{}` | Igual que `labels` | Alias. Si una clave está en ambos, **gana `tags`**. |
| `connectivity` | No | omitir | Lista. Ver [connectivity](#connectivity) | **Opcional.** Sin bloque = sin Private Endpoint (público, con API key/mTLS). Con `type: private` = PE. |
| `search_attributes` | No | `[]` | Ver [search_attributes](#search_attributes) | Atributos custom de visibilidad. |
| `service_accounts` | No | `[]` | Ver [service_accounts](#service_accounts) | Identidades de workers + API keys (van a Vault). |
| `users` | No | `[]` | Ver [users](#users) | Personas (email) con acceso al namespace. |

### `name`

- Regex: empieza con letra, `[a-z0-9-]`, 2–64 caracteres, no termina en `-`.
- Prefijo del env: `peve-dev`, `peve-cert` o `peve-prod`. Suffix opcional para más de un namespace: `peve-dev-pagos`.
- El `codapp` del nombre es **minúsculas** (`peve`), la carpeta del repo suele ser **mayúsculas** (`PEVE`).
- **No renombres** un namespace ya aplicado.

### Regiones

Códigos tal cual Temporal (no `eastus2` de Azure). Tienen que existir en `PEVE-orchestration-automation/scripts/ci/temporal-ha-pairs.json`.

| Env | Cuántas | Ejemplo PEVE (Azure DES) |
|---|---|---|
| `dev`, `cert` | 1 | `azure-centralus` |
| `prod` | **2** y que sean **par HA** | `azure-centralus` + `aws-us-east-1` |

`azure-centralus` **no** tiene réplica Azure–Azure. Prod desde Central US es **multi-cloud**. Pares y excepciones: IAC [`docs/TEMPORAL-HA.md`](../../PEVE-orchestration-automation/docs/TEMPORAL-HA.md).

Orden: la primera es la primaria. No las intercambies después.

### Auth (API key o mTLS)

A elección **por namespace**. Default = API key (como PEVE hoy). No es un campo del worker: es del namespace en Temporal Cloud.

| Modo | YAML | Worker se conecta con |
|---|---|---|
| API key | `api_key_auth: true` (o omitís el campo) | API key del SA (Vault, post-apply) |
| mTLS | `api_key_auth: false` **y** CA | Client cert firmado por esa CA |
| Ambos | `api_key_auth: true` **y** CA | Los dos, si Temporal lo habilita en la cuenta |

`false` **sin** path de Vault lo rechaza el CI. La **CA pública** y la clave privada del client cert viven en HashiCorp Vault. Este YAML **no** lleva el PEM: solo el path. El CD (`fetch-temporal-ca-vault.sh`) lo baja a un `.pem` temporal en el runner y Terraform se lo pasa a Temporal. Ese archivo **no** se commitea.

```yaml
api_key_auth: false
accepted_client_ca_vault:
  path: dev/peve/temporal/mtls/peve-dev   # KV v2, sin el mount
  field: pem                              # default
  # mount: peve/kv2                       # default
```

| Subcampo | Obligatorio | Default | Qué es |
|---|---|---|---|
| `path` | Sí | — | Secret KV2 **después** del mount. Convención: `{dev\|cert\|prod}/{codapp}/temporal/mtls/{namespace}` |
| `field` | No | `pem` | Campo del secret con el PEM (`-----BEGIN CERTIFICATE-----`) |
| `mount` | No | `peve/kv2` | Mount KV2 |

Cómo cargar la CA (una vez, Security / el equipo de app):

```bash
vault kv put -mount=peve/kv2 dev/peve/temporal/mtls/peve-dev pem=@client-ca.pem
```

Varios namespaces del mismo env pueden apuntar al **mismo** path (una CA de entorno). Rotar = actualizar el secret y un `apply` (el CD vuelve a bajar el PEM).

La clave **privada** del client cert del worker es otro secret (no este path, no este IAC).

`accepted_client_ca` / `accepted_client_ca_file` en el YAML quedan solo para pruebas locales; en el banco usá Vault.

`certificate_filters` (opcional; lista vacía no: o la omitís). Temporal solo deja pasar client certs cuyo DN calce **al menos un** filtro:

| Campo | Obligatorio | Qué filtra |
|---|---|---|
| `common_name` | No | CN |
| `organization` | No | O |
| `organizational_unit` | No | OU |
| `subject_alternative_name` | No | SAN |

Endpoint gRPC: con API key usás `endpoints.grpc_address`; con mTLS, `endpoints.mtls_grpc_address`. El SDK apunta al que corresponda.

### `labels` / `tags`

| Regla | Valor |
|---|---|
| Máximo | 10 pares (suma de `labels` + `tags`) |
| Key y value | 1–63 chars, solo `a-z 0-9 . _ - @` |
| Mayúsculas | **No**. Temporal las rechaza |
| Tipo | Solo string (`env: "dev"`, no `env: 1`) |

Mínimo útil:

```yaml
labels:
  codapp: peve
  env: dev
```

---

## `connectivity`

**Opcional.** Qué hacer en cada camino (pasos, worker, DNS, pasar de uno a otro): **[PRIVATELINK.md](PRIVATELINK.md)**.

| Camino | YAML | Red del worker |
|---|---|---|
| **A. Internet (sin PE)** | **Omití** `connectivity` | Egress público a `*.tmprl.cloud:7233` |
| **B. Private Endpoint** | `type: private` + ID | VNet → PE. Mismo host del namespace; DNS privado |

Auth (API key / mTLS) no cambia con la red. Con PE: **uno por entorno** (prod HA: uno por región); las rules son **por namespace** (mismo ID en cada YAML). El PE lo crea Cloud Governance.

`connectivity.name` debe ser **único en todo el env** si el bloque existe (un `name` por namespace; el **ID del PE** sí se repite).

| Campo | Obligatorio | Valores | Qué es |
|---|---|---|---|
| `name` | Sí, si hay entrada | Unique en el env. Ej. `{codapp}-{env}-pl-centralus` | Nombre de la rule en Terraform (no el del PE de Azure). |
| `type` | Sí, si hay entrada | `private` \| `public` | Con PE: `private`. `public` es rule pública explícita (casi nunca hace falta: omitir el bloque alcanza). |
| `region` | Si `private` | Uno de los `regions` del namespace | Región Temporal de **esta** rule. |
| `azure_pe_resource_id` | Si `private` y `region` es `azure-*` | ARM del Private Endpoint | Lo entrega Governance. |
| `connection_id` | Si `private` y AWS (`vpce-…`) o GCP | ID del endpoint | AWS: `vpce-…`. GCP: PSC. |
| `gcp_project_id` | Si `private` y `region` es `gcp-*` | Project ID GCP | Junto con `connection_id`. |
| `enable_stable_ips` | No | `true` / `false` | AWS PrivateLink IPs estables. No lo pongas salvo que Governance lo pida. |

Prod HA **con PE**: una rule por región del par. Prod **sin PE** igual exige 2 regiones (eso es réplica de Temporal, no PrivateLink).

```yaml
# Con PE (cuando Governance entregue el ARM):
connectivity:
  - name: peve-dev-pl-centralus
    type: private
    region: azure-centralus
    azure_pe_resource_id: "/subscriptions/…/privateEndpoints/pe-temporal-dev"
```

---

## `search_attributes`

Atributos **custom** (visibilidad / listado de workflows). No uses los built-in de Temporal (`WorkflowId`, `WorkflowType`, `RunId`, `StartTime`, `ExecutionStatus`, `TaskQueue`, …).

| Campo | Obligatorio | Valores |
|---|---|---|
| `name` | Sí | Identificador. Unique **dentro del namespace**. |
| `type` | Sí | `bool` \| `datetime` \| `double` \| `int` \| `keyword` \| `keyword_list` \| `text` |

El **tipo no se cambia** después: hay que borrar el atributo y crear otro (recreate). El nombre del atributo en el worker tiene que coincidir.

```yaml
search_attributes:
  - name: CustomerId
    type: keyword
  - name: OrderAmount
    type: double
```

---

## `service_accounts`

Un SA = identidad de worker (o herramienta). El `name` debe ser **único en todo el env**.

| Campo | Obligatorio | Default | Valores | Qué es |
|---|---|---|---|---|
| `name` | Sí | — | Unique en el env | Nombre en Temporal. |
| `permission` | No | `write` | `admin` \| `write` \| `read` | Rol **en este namespace**. Workers: `write`. |
| `account_access` | No | `developer` | `admin` \| `developer` \| `read` \| `financeadmin` \| `metricsread` | Rol a **nivel cuenta** Temporal. Dejá `developer`. |
| `extra_namespaces` | No | `[]` | Lista `{name, permission}` | Acceso extra a **otros** namespaces del **mismo** env (el `name` tiene que existir en otro YAML). Default de `permission` ahí: `read`. |
| `api_keys` | No | `[]` | Ver abajo | Tokens de **Cloud API** del SA. En modo mTLS el worker no las usa para gRPC del namespace; igual sirven para API de cuenta. El CD las sube a Vault. |

### `api_keys[]`

`display_name` único en **todo el env**. Rotar = **otra** entrada (otro `display_name`); no recicles el nombre si querés un token nuevo.

| Campo | Obligatorio | Default | Valores |
|---|---|---|---|
| `display_name` | Sí | — | Unique en el env. Ej. `{sa-name}-key` |
| `expiry_time` | Sí | — | RFC3339 UTC, ej. `"2028-12-31T00:00:00Z"` |
| `disabled` | No | `false` | `true` deshabilita la key sin borrarla |

Tras un `apply`, Vault:

`{dev\|cert\|prod}/{codapp}/temporal/apikeys/{display_name}` → campo `token` (mount `peve/kv2`).

---

## `users`

Personas de consola Temporal (invitación por email). El IAC fija `account_access: developer`.

| Campo | Obligatorio | Default | Valores |
|---|---|---|---|
| `email` | Sí | — | Unique en **todo el env** (clave Terraform). Un email no puede listarse en dos YAML del mismo apply. |
| `permission` | No | `write` | `admin` \| `write` \| `read` | Rol **en este** namespace. |

Si alguien necesita dos namespaces, hoy hay que listarlo en uno solo (el módulo no une accesos por email).

---

## Qué no se toca in-place

| Campo | Si lo cambiás |
|---|---|
| `name` | Destroy + create (namespace nuevo, historia no se mueve) |
| `regions` | Igual. Elegí bien en el primer apply |
| `search_attributes[].type` | Recreate de ese atributo |
| SQL / workers / task queues | **No van en este YAML** |

Sí se puede en un apply posterior: `retention_days`, `labels`, `connectivity` (IDs), SA, keys, users, search attributes **nuevos**.

---

## Qué no va acá

- PEM / clave privada del client cert (CA pública en Vault; el YAML solo el path)
- Creación del Private Endpoint, VNet, DNS (Governance)
- Codec server, SSO/SCIM, project id
- Workers, task queues de la app, failover
- El Account API key de gobernanza (vive en Vault del CD, no en el YAML)

---

## Mínimo (dev, un namespace, Azure)

```yaml
name: peve-dev
regions:
  - azure-centralus
retention_days: 14
api_key_auth: true
labels:
  codapp: peve
  env: dev
# Sin connectivity = internet (camino A). Con PE: docs/PRIVATELINK.md camino B.
service_accounts:
  - name: peve-dev-worker
    permission: write
    api_keys:
      - display_name: peve-dev-worker-key
        expiry_time: "2028-12-31T00:00:00Z"
```

Ejemplo lleno (users, search, segundo namespace, Nexus): `PEVE/dev/namespaces/` y `PEVE/dev/nexus/`.
