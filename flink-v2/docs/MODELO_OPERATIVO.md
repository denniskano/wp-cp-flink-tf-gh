# Modelo operativo Flink v2

Contrato para que una aplicación (**CODAPP**) declare sus compute pools y statements de Confluent Cloud Flink en YAML, los integre por **fork y pull request**, y pida el despliegue con un **ticket Jira**.

El SQL, los CFU y el ciclo de vida de pools y statements están en [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md) y [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md). Aquí no se documenta la automatización interna de plataforma.

> Alcance: Confluent Cloud Dedicated (Kafka + Schema Registry). Región de referencia: Azure East US 2.

---

## Qué hace el equipo de la aplicación

1. **Fork** de `PEVE-stream-processing-resources-v1`.
2. Crea la carpeta **`{CODAPP}/`** con la estructura de este documento.
3. **Pull request** al repositorio central.
4. **Ticket Jira** para desplegar. El **tipo de ticket** determina el entorno: desarrollo, certificación o producción.

La aplicación solo versiona YAML en su carpeta. No interviene en cómo plataforma aplica el cambio.

---

## Prerrequisito: Service Account

Antes de pedir el despliegue de **statements**, el Service Account que ejecutará el SQL tiene que existir.

Eso **no** se hace en este repositorio. Es **otro ticket Jira** (otro proceso): crea el SA y la API key de Flink y los deja en **HashiCorp Vault**.

Cuando ese ticket cierra, anota en tus YAML los nombres que te entreguen (`service-account` y `api-key`). Sin ese alta, el despliegue de statements no puede completar.

Los compute pools no dependen de ese SA de ejecución. Aun así, conviene tener el SA listo antes de armar el pipeline (RBAC y statements lo referencian).

Formato de los nombres (el proceso de alta los emite así):

```
SA_AZC_{DES|CER|PRO}_{CODAPP4}_{3 o 8 caracteres}_{01-99}
AK_AZC_{DES|CER|PRO}_{CODAPP4}_FLINK_{3 o 8 caracteres}_{01-99}
```

Ejemplo: `SA_AZC_DES_APPV_CDPEVEFL_01`, `AK_AZC_DES_APPV_FLINK_CDPEVEFL_01`.

---

## Estructura de directorios

Una carpeta raíz por aplicación en `PEVE-stream-processing-resources-v1`. `CODAPP` son **4 letras** (`PEVE`) o **`XXXX-PARTNER`** (`APPV-PARTNER`).

```
{CODAPP}/
└── ccloud-flink/
    ├── desa/
    │   ├── compute-pool/
    │   │   └── cc-compute-pools.yaml
    │   └── {pipeline}/
    │       ├── security/
    │       │   └── cc-azure_eu2_kafka01-rbac-des.yaml
    │       └── statement/
    │           ├── ddl/          # *.yaml
    │           └── dml/          # *.yaml  (o .gitkeep si aún no hay DML)
    ├── cert/
    │   └── … misma forma …
    └── prod/
        └── … misma forma …
```

| Pieza | Ruta |
|---|---|
| Pools | `{CODAPP}/ccloud-flink/{desa\|cert\|prod}/compute-pool/cc-compute-pools.yaml` |
| Pipeline | `{CODAPP}/ccloud-flink/{desa\|cert\|prod}/{pipeline}/` |
| RBAC | `.../{pipeline}/security/` |
| DDL / DML | `.../{pipeline}/statement/ddl/*.yaml` y `.../dml/*.yaml` |

- Entornos en minúsculas: `desa`, `cert`, `prod`. Un YAML de pools por entorno.
- El nombre de la carpeta `{pipeline}` es el que irás en el ticket de statements.
- Solo `*.yaml` en `ddl/` y `dml/` (sin subcarpetas).
- Empieza por `desa`. En cert y prod replica el pipeline y cambia pool, SA y API key al entorno.

Ejemplos para copiar: `APPV-PARTNER/` (un pipeline en desa y cert) y `PEVE/` (varios pipelines en desa).

---

## YAML que hay que llenar

### Compute pool — `cc-compute-pools.yaml`

```yaml
compute_pools:
  - cloud: "AZURE"
    region: "eastus2"
    max_cfu: 5
    pool_name: "CP_AZC_EU2_DES_XXXX_01"
```

`pool_name` debe coincidir con `flink-compute-pool` de los statements y con el `compute-pool` del RBAC.

```
CP_AZC_EU2_{DES|CER|PRO}_{CODAPP}_{nn}
```

Ejemplos: `CP_AZC_EU2_DES_PEVE_01`, `CP_AZC_EU2_DES_APPV_PARTNER_01`. Dimensionamiento: [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md).

### Statements — `statement/ddl/*.yaml` y `statement/dml/*.yaml`

Prefijo numérico (`01_`, `02_`). Campos:

| Campo | DDL | DML |
|---|---|---|
| `statement-name` | Sí (único, ≤ 72 caracteres; no lo renombres después) | Sí |
| `flink-compute-pool` | Sí | Sí |
| `service-account` / `api-key` | Sí (nombres del ticket de alta de SA) | Sí |
| `statement` | SQL | SQL |
| `stopped` | — | `"false"` o `"true"` |

El nombre de tabla Flink es el nombre del topic. No uses `'kafka.topic'`. El SQL es inmutable: para cambiarlo, nuevo `statement-name` (`…-v2`). Detalle: [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md).

### RBAC — `security/*.yaml`

Permisos del **mismo** SA de los statements: topics, subjects, compute pool (`FlinkDeveloper`) y transactional-id `_confluent-flink_` (PREFIXED, Read/Write).

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

---

## Despliegue (Jira)

Con el PR mergeado, abre el ticket de despliegue en Jira. El **tipo de ticket** elige el entorno (desarrollo, certificación o producción).

En el ticket indica:

- `CODAPP` (carpeta raíz)
- Qué desplegar: **compute pools** y/o **statements**
- Si son statements: nombre de la carpeta `{pipeline}`
- Entorno implícito en el tipo de ticket

Orden:

1. Ticket de **alta de Service Account** (prerrequisito de statements) → nombres en YAML y Vault.
2. PR con pools → ticket de despliegue de **compute pools**.
3. PR con `security` + DDL/DML → ticket de despliegue de **statements** (el pool de ese entorno ya tiene que existir).

---

## Checklist del PR

- [ ] Carpeta raíz = `CODAPP` (4 letras o `XXXX-PARTNER`).
- [ ] `cc-compute-pools.yaml` en el entorno que vas a pedir.
- [ ] `pool_name` igual en pools, statements y RBAC.
- [ ] Pipeline con `security/`, `statement/ddl/` y `statement/dml/`.
- [ ] Statements con `statement-name`, pool, SA, API key y SQL; DML con `stopped`.
- [ ] SA y API key ya dados de alta (ticket Jira de SA) y en el formato de este documento.
- [ ] Sin secretos en el YAML.
- [ ] Topics y schemas del SQL existen, o el DDL/RBAC los cubre.

---

## Referencias

- [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md)
- [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md)
- [Compute Pools](https://docs.confluent.io/cloud/current/flink/concepts/compute-pools.html)
- [Flink statements](https://docs.confluent.io/cloud/current/flink/concepts/statements.html)
- [Flink RBAC](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html)
