# Modelo operativo Flink v2

Documentación base para que **una aplicación (CODAPP)** despliegue sus **compute pools** y **statements** de Confluent Cloud Flink **sin tocar Terraform**.

El equipo de la aplicación:

1. Hace **fork** del repositorio de configuración `PEVE-stream-processing-resources-v1`.
2. Crea **su carpeta `{CODAPP}/`** con la estructura de este documento.
3. Abre un **pull request** hacia el repositorio central.
4. Dispara los GitHub Actions del repositorio de IaC `PEVE-event-driven-resources-v2` con su `CODAPP` y, para statements, el nombre del pipeline.

El detalle de CFU, Autopilot y SQL está en [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md) y [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md). Este archivo es el contrato de carpetas, YAML y despliegue.

> Alcance: Confluent Cloud **Dedicated** (Kafka Dedicated + Schema Registry). Cluster de referencia: Azure East US 2.

---

## Objetivos

- **Autonomía**: cada CODAPP versiona su Flink en su carpeta.
- **Contrato único**: CI resuelve rutas fijas; si la carpeta no cumple el contrato, el workflow no encuentra YAML.
- **Separación de roles**: la aplicación declara *qué* desplegar (YAML); plataforma despliega *cómo* (Terraform + Actions + Vault).
- **Trazabilidad**: cambios en pull request, un state Terraform por CODAPP (pools) y por pipeline (statements).
- **Promoción por entorno**: las mismas piezas en `desa` → `cert` → `prod`, con nombres de pool, SA y API key del entorno.

---

## Dos repositorios

| Repositorio | Qué contiene | Quién lo cambia |
|---|---|---|
| `PEVE-stream-processing-resources-v1` | YAML: compute pools, DDL, DML, RBAC | **La aplicación** (fork + PR) |
| `PEVE-event-driven-resources-v2` | Terraform, scripts, GitHub Actions | Plataforma / PEVE (no es el repo de la app) |

CI del repo de IaC clona el repo de configuración en `./externo` (rama `master` del org `BCP-Integration-Automation`) y aplica:

```
./externo/{CODAPP}/ccloud-flink/{desa|cert|prod}/...
```

El input `CODAPP` del workflow **tiene que coincidir** con el nombre de la carpeta raíz. El input `pipeline_flink` **tiene que coincidir** con el nombre de la carpeta del pipeline.

```
Aplicación                          Plataforma
─────────                          ──────────
fork + carpeta {CODAPP}/     →     checkout ./externo
YAML pools / ddl / dml / rbac →    Terraform generate + plan/apply
PR a master                  →     GitHub Actions (DES / CER / PRO)
```

La aplicación **no** edita módulos Terraform, workflows ni secretos. Declara Service Account y API key **por nombre**; las credenciales salen de Vault.

---

## Estructura del repositorio de configuración

Contrato de `PEVE-stream-processing-resources-v1`. Cada aplicación ocupa **una carpeta raíz**.

```
PEVE-stream-processing-resources-v1/
├── PEVE/                          # CODAPP de 4 letras
│   └── ccloud-flink/
│       └── desa/
│           ├── compute-pool/
│           │   └── cc-compute-pools.yaml
│           ├── pipeline-nombre-caso-negocio-compras-04/
│           │   ├── security/
│           │   │   └── cc-azure_eu2_kafka01-rbac-des.yaml
│           │   └── statement/
│           │       ├── ddl/
│           │       │   └── *.yaml
│           │       └── dml/
│           │           └── *.yaml
│           └── pipeline-nombre-caso-negocio-ventas-04/
│               ├── security/
│               └── statement/{ddl,dml}/
├── APPV-PARTNER/                  # componente partner: XXXX-PARTNER
│   └── ccloud-flink/
│       ├── desa/
│       │   ├── compute-pool/cc-compute-pools.yaml
│       │   └── pipeline-pos-transaction-filter/
│       │       ├── security/
│       │       └── statement/{ddl,dml}/
│       └── cert/
│           ├── compute-pool/cc-compute-pools.yaml
│           └── pipeline-pos-transaction-filter/
│               ├── security/
│               └── statement/{ddl,dml}/
└── PEVE-PARTNER/
    └── ccloud-flink/desa/...
```

En el repo hay ejemplos reales: `PEVE` (varios pipelines en desa), `APPV-PARTNER` (mismo pipeline en desa y cert) y `PEVE-PARTNER`. Cópialos; no inventes otra jerarquía.

### Carpetas que CI exige

| Pieza | Ruta (obligatoria) |
|---|---|
| Compute pools | `{CODAPP}/ccloud-flink/{desa\|cert\|prod}/compute-pool/cc-compute-pools.yaml` |
| Pipeline | `{CODAPP}/ccloud-flink/{desa\|cert\|prod}/{pipeline_flink}/` |
| RBAC | `.../{pipeline_flink}/security/` (YAML de permisos del SA que ejecuta Flink) |
| DDL | `.../{pipeline_flink}/statement/ddl/*.yaml` |
| DML | `.../{pipeline_flink}/statement/dml/*.yaml` |

Reglas:

- Entornos en minúsculas: `desa`, `cert`, `prod`. No mezclar DES/CER/PRO en el mismo YAML de pools.
- Un archivo de pools por entorno, nombre fijo `cc-compute-pools.yaml`.
- Un pipeline = una carpeta. El nombre de esa carpeta es el input `pipeline_flink`.
- Solo `*.yaml` en `ddl/` y `dml/` (un nivel; CI no recorre subcarpetas).
- Si aún no hay DML, deja `dml/` con `.gitkeep` para versionar la carpeta vacía.
- `CODAPP` de 4 letras (`PEVE`, `BADI`, `APPV`) o partner `XXXX-PARTNER` (`APPV-PARTNER`).

---

## Paso a paso: fork y carpeta propia

### 1. Fork

Haz fork de `BCP-Integration-Automation/PEVE-stream-processing-resources-v1` (o el remoto que Plataforma indique). Trabaja en una rama; no subas secretos ni SQL con credenciales.

### 2. Crear `{CODAPP}/`

Sustituye `XXXX` por tu código de aplicación y `pipeline-mi-caso` por un nombre estable del caso de negocio (minúsculas, guiones).

```
XXXX/
└── ccloud-flink/
    ├── desa/
    │   ├── compute-pool/
    │   │   └── cc-compute-pools.yaml
    │   └── pipeline-mi-caso/
    │       ├── security/
    │       │   └── cc-azure_eu2_kafka01-rbac-des.yaml
    │       └── statement/
    │           ├── ddl/
    │           └── dml/
    ├── cert/
    │   ├── compute-pool/
    │   │   └── cc-compute-pools.yaml
    │   └── pipeline-mi-caso/
    │       ├── security/
    │       └── statement/{ddl,dml}/
    └── prod/
        ├── compute-pool/
        │   └── cc-compute-pools.yaml
        └── pipeline-mi-caso/
            ├── security/
            └── statement/{ddl,dml}/
```

Empieza por **desa**. Replica la misma carpeta de pipeline en cert y prod cuando el diseño esté validado. Cambia pool, SA y API key al entorno; no reutilices nombres de DES en PRO.

Referencias para copiar:

- Pools: `APPV-PARTNER/ccloud-flink/desa/compute-pool/cc-compute-pools.yaml`
- Pipeline completo: `APPV-PARTNER/ccloud-flink/desa/pipeline-pos-transaction-filter/`
- Varios pipelines y RBAC por SA: `PEVE/ccloud-flink/desa/`

### 3. Pull request

El PR debe dejar las rutas que CI va a leer. Tras el merge a `master`, el workflow del repo de IaC ya puede clonar tu carpeta.

---

## Qué hay que llenar

### Compute pool — `cc-compute-pools.yaml`

```yaml
compute_pools:
  - cloud: "AZURE"
    region: "eastus2"
    max_cfu: 5
    pool_name: "CP_AZC_EU2_DES_XXXX_01"
```

| Campo | Qué es |
|---|---|
| `cloud` / `region` | Los del cluster Kafka (Azure `eastus2`). Cross-region no está soportado. |
| `max_cfu` | Techo de CFUs del pool. Se puede **subir**; **no** se puede bajar. |
| `pool_name` | Nombre único. Debe coincidir con `flink-compute-pool` de los YAML de statements y con `resource_type: compute-pool` del RBAC. |

Convención de nombre:

```
CP_AZC_EU2_{DES|CER|PRO}_{CODAPP}_{nn}
```

Ejemplos: `CP_AZC_EU2_DES_PEVE_01`, `CP_AZC_EU2_DES_APPV_PARTNER_01`.

Un pool puede servir varios statements. No mezcles cargas críticas y no críticas en el mismo pool. Criterio de `max_cfu`: [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md).

### Statement DDL — `statement/ddl/*.yaml`

Define o ajusta tablas (CREATE / ALTER). Prefijo numérico para orden de lectura (`01_`, `02_`).

Campos obligatorios:

| Campo | Uso |
|---|---|
| `statement-name` | Único, máximo 72 caracteres. No lo cambies después del primer apply. |
| `flink-compute-pool` | Un `pool_name` de `cc-compute-pools.yaml` de **ese** entorno. |
| `service-account` | SA que **ejecuta** el statement (no el SA de Terraform). |
| `api-key` | API key Flink de ese SA. El secret está en Vault; aquí solo el nombre. |
| `statement` | SQL. En Confluent Cloud el nombre de tabla es el nombre del topic; no uses `'kafka.topic'`. |

`${catalog_name}`, `${cluster_name}` y `${environment}` se sustituyen en CI si los usas. Los workflows de desa/cert/prod ya fijan catálogo y cluster (`bcp_desa` / `AZURE_EU2_DESA_KAFKA01`, etc.).

### Statement DML — `statement/dml/*.yaml`

Igual que DDL, más `stopped: "false"` (o `"true"` para pausar sin borrar). El SQL de un statement es **inmutable**: un cambio de `statement` recrea el recurso y **pierde offsets**. Versiona con `statement-name` nuevo (`...-v2`) en lugar de editar el SQL in-place. Detalle: [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md).

### RBAC — `security/*.yaml`

Permisos del SA que corre el SQL: topics, subjects de Schema Registry, compute pool (`FlinkDeveloper`) y transactional-id `_confluent-flink_` (PREFIXED, Read/Write).

El `resource_name` de `compute-pool` debe ser el mismo `pool_name`. Sin este YAML el statement no arranca aunque el SQL sea correcto.

Plantilla mínima (ajusta principal, topics y pool):

```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_XXXX_CDXXXXFL_01
      resources:
      - resource_type: subject
        resource_name: 'azc-xxxx-mi-topic-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
        - operation: DeveloperWrite
      - resource_type: topic
        resource_name: 'azc-xxxx-mi-topic'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
        - operation: DeveloperWrite
      - resource_type: compute-pool
        resource_name: CP_AZC_EU2_DES_XXXX_01
        resource_region: azure.eastus2
        pattern_type: LITERAL
        role:
        - operation: FlinkDeveloper
      - resource_type: transactional-id
        resource_name: '_confluent-flink_'
        pattern_type: PREFIXED
        role:
        - operation: DeveloperRead
        - operation: DeveloperWrite
```

CI valida el formato de nombres:

```
SA_AZC_{DES|CER|PRO}_{CODAPP4}_{3 o 8 caracteres}_{01-99}
AK_AZC_{DES|CER|PRO}_{CODAPP4}_FLINK_{3 o 8 caracteres}_{01-99}
```

Ejemplos válidos: `SA_AZC_DES_APPV_CDPEVEFL_01`, `AK_AZC_DES_APPV_FLINK_CDPEVEFL_01`.

---

## Cómo se despliega

Los workflows viven en `PEVE-event-driven-resources-v2`. Se lanzan a mano (`workflow_dispatch`). Rama de automatización: `automation-v3-flink-stream-processing`.

### Compute pools

| Entorno | Workflow |
|---|---|
| DES | `deploy-compute-pools-desa-2-0.yml` |
| CER | `deploy-compute-pools-cert-2-0.yml` |
| PRO | `deploy-compute-pools-prod-2-0.yml` |

Inputs: `action` = `plan-apply`, `CODAPP` = carpeta raíz (ej. `PEVE` o `APPV-PARTNER`).

CI lee `./externo/{CODAPP}/ccloud-flink/{desa\|cert\|prod}/compute-pool/cc-compute-pools.yaml`.

### Statements (RBAC + DDL + DML)

| Entorno | Workflow |
|---|---|
| DES | `deploy-flink-statements-desa-2-0.yml` |
| CER | `deploy-flink-statements-cert-2-0.yml` |
| PRO | `deploy-flink-statements-prod-2-0.yml` |

Inputs: `action` (`plan-apply` o `destroy`), `CODAPP`, `pipeline_flink` (nombre **exacto** de la carpeta).

Orden interno del workflow: RBAC (`security/`) → DDL → DML.

### Orden que debe seguir la aplicación

1. Merge del YAML de **pools** en `master`.
2. `deploy-compute-pools-*-2-0` con tu `CODAPP`. Esperar pool `PROVISIONED`.
3. Merge del YAML de **pipeline** (security + ddl + dml).
4. `deploy-flink-statements-*-2-0` con el mismo `CODAPP` y el `pipeline_flink`.
5. En Console: statements `RUNNING` (DML) o `COMPLETED` (DDL one-shot).

Un statement no puede ejecutarse si el pool aún no existe.

State en Azure (no lo gestiona la app): pools `tf-flink-cps-*` por CODAPP; statements `tf-flink-stm-*` por CODAPP y pipeline.

---

## Checklist antes del PR

- [ ] Carpeta raíz = `CODAPP` (4 letras o `XXXX-PARTNER`).
- [ ] Existe `ccloud-flink/{desa|cert|prod}/compute-pool/cc-compute-pools.yaml`.
- [ ] `pool_name` alineado entre pools, `flink-compute-pool` y RBAC `compute-pool`.
- [ ] Carpeta `{pipeline_flink}` con `security/`, `statement/ddl/`, `statement/dml/`.
- [ ] Cada YAML de statement tiene `statement-name`, `flink-compute-pool`, `service-account`, `api-key`, `statement`.
- [ ] DML incluye `stopped`.
- [ ] SA y API key cumplen el regex y existen en Vault (pide el alta a Plataforma si es SA nuevo).
- [ ] Topics y schemas del SQL ya existen, o el DDL/RBAC los cubre (`DeveloperManage` en topic si CREATE TABLE crea topic).
- [ ] No hay secretos en el repo.
- [ ] `statement-name` ≤ 72 caracteres y no se reutiliza para SQL distinto.

---

## Qué no hace este modelo

- No sustituye el alta de topics, schemas, Service Accounts ni API keys (eso es previo o paralelo con Plataforma).
- No incluye conectores Kafka, eCKU ni Flink billing más allá del pool (`max_cfu`).
- No permite bajar `max_cfu` ni editar el SQL de un statement in-place.
- Un conector o un statement **pausado** no es equivalente a “dejar de facturar” en todos los productos; en Flink, `stopped: true` deja de consumir CFU.

---

## Troubleshooting rápido (aplicación)

| Síntoma | Causa típica | Qué revisar |
|---|---|---|
| CI no encuentra YAML de pools | `CODAPP` o entorno distintos a la carpeta | `./externo/{CODAPP}/ccloud-flink/{desa\|cert\|prod}/compute-pool/cc-compute-pools.yaml` |
| CI no encuentra el pipeline | `pipeline_flink` ≠ nombre de carpeta | `.../ccloud-flink/{entorno}/{pipeline_flink}/statement/` |
| SA / API key rechazados | Formato o vacío | Regex de este documento; campos `service-account` y `api-key` |
| Statement FAILED por permisos | RBAC incompleto | Topic, subject, compute-pool, transactional-id del SA |
| Statement no arranca | Pool no provisionado | Desplegar pools **antes** que statements |
| Plan propone recreate del DML | Cambió `statement` o el nombre del YAML | Nuevo `statement-name`; offsets se pierden |

---

## Referencias

- [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md) — CFU, Autopilot, lifecycle del pool, RBAC por capas.
- [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md) — DDL/DML, inmutabilidad, headers, prácticas SQL.
- [Compute Pools](https://docs.confluent.io/cloud/current/flink/concepts/compute-pools.html)
- [Flink statements](https://docs.confluent.io/cloud/current/flink/concepts/statements.html)
- [Flink RBAC](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html)
