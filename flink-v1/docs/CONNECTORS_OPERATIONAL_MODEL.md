# Modelo operativo — conectores full-managed

Contrato para que una aplicación (**CODAPP**) declare conectores Kafka Connect full-managed en YAML, agrupados por **caso de uso**, y pida el despliegue con el workflow de GitHub Actions.

RBAC de topics/subjects: [CONNECTOR_DLQ_PERMISSIONS.md](./CONNECTOR_DLQ_PERMISSIONS.md).

> Alcance: Confluent Cloud Dedicated. El workflow actual despliega **solo DES** (`desa`). Las carpetas `cert/` y `prod/` se versionan para cuando existan los workflows de esos entornos.

---

## Qué hace el equipo de la aplicación

1. **Prerrequisito: Service Account** del conector (alta aparte; el SA queda en HashiCorp Vault).
2. Topics (y DLQ si aplica) ya creados en el cluster.
3. Carpeta `{CODAPP}/{desa|cert|prod}/{use-case}/` con `connects/` y `security/`.
4. Pull request. Despliegue con **Run workflow**.

La aplicación versiona YAML. No interviene en cómo plataforma aplica el cambio.

### Prerrequisitos que no salen de este repo

| Qué | Quién |
|---|---|
| Service Account del conector | Proceso de alta (el nombre va en `vault.service_account`) |
| Topics de origen/destino | Ya deben existir |
| Topic DLQ `{topic}-dlq` | Ya debe existir si el YAML tiene `errors.tolerance` |
| Secretos (keys, passwords) | HashiCorp Vault; el YAML solo declara `path` y `field` |

---

## Unidad de despliegue: el caso de uso

**`plan`, `apply` y `destroy` son por use-case**, no por conector.

Con **CODAPP** + **use_case** basta. El workflow toma **todos** los `*.yaml` de `connects/` y el RBAC de `security/` de esa carpeta.

El input **connector** es **obligatorio solo en `pause` y `resume`**. En `plan` / `apply` / `destroy` se ignora.

| Acción | Inputs | Efecto |
|---|---|---|
| `plan` | `CODAPP`, `use_case` | Muestra el diff de **todos** los conectores y el RBAC del use-case |
| `apply` | `CODAPP`, `use_case` | Crea, actualiza o borra según los YAML de `connects/` y `security/` |
| `destroy` | `CODAPP`, `use_case` | Elimina **todo** el use-case (conectores y bindings de ese módulo) |
| `pause` | `CODAPP`, `use_case`, **`connector`** | Pausa **un** conector (in-place). Los demás no se tocan |
| `resume` | `CODAPP`, `use_case`, **`connector`** | Reanuda **un** conector |

`connector` = nombre del archivo en `connects/` **sin** `.yaml` (ej. `ccloud-azure-blob-storage-sink-connector-01`).

---

## Estructura de directorios

```
{CODAPP}/
├── desa/
│   └── {use-case}/
│       ├── connects/
│       │   └── {connector-name}.yaml     # un YAML por conector
│       └── security/
│           └── cc-azure_eu2_kafka01-rbac-des.yaml
├── cert/
│   └── {use-case}/
│       ├── connects/
│       └── security/
└── prod/
    └── {use-case}/
        ├── connects/
        └── security/
```

| Pieza | Ruta |
|---|---|
| Conectores | `{CODAPP}/{desa\|cert\|prod}/{use-case}/connects/*.yaml` |
| RBAC | `{CODAPP}/{desa\|cert\|prod}/{use-case}/security/*.yaml` |

- Entornos en minúsculas: `desa`, `cert`, `prod`. El directorio **es** el entorno; **no** uses prefijo `dev-` / `cert-` / `prod-` en el nombre del archivo.
- Solo `*.yaml` (no `*.yml`, no subcarpetas).
- `{use-case}` es el valor del input `use_case` (ej. `use-case-name-01`).
- `security/` es **obligatorio** (el directorio debe existir). Si el use-case no tiene bindings aún, deja la carpeta y añade YAML cuando correspondan.
- Ejemplo: `PEVE/desa/use-case-name-01/`.

---

## YAML del conector (`connects/`)

Un archivo por conector. Config no sensible + referencia a Vault. **No commitear secretos.**

```yaml
name: "peve-azure-blob-storage-sink-connector-01"
status: "RUNNING"   # RUNNING | PAUSED

config_nonsensitive:
  name: "peve-azure-blob-storage-sink-connector-01"
  connector.class: "AzureBlobSink"
  kafka.auth.mode: "SERVICE_ACCOUNT"
  tasks.max: "1"
  errors.tolerance: "all"
  topics: "azc-peve-connect-test"
  # resto de propiedades del conector (sin credenciales)

vault:
  service_account: "SA_AZC_DES_PEVE_BLOB_01"
  api-key: "AK_AZC_DES_PEVE_BLOB_01"
  secrets:
    azblob.account.key:
      path: "peve/data/dev/peve/azure/ST_PEVE_CONNECT_DEV"
      field: "access_key"
```

| Campo | Rol |
|---|---|
| Nombre del **archivo** | Key de Terraform. No lo cambies después del primer `apply` |
| `name` / `config_nonsensitive.name` | Nombre en Confluent Cloud. Tampoco lo cambies después del primer `apply` |
| `status` | `RUNNING` o `PAUSED`. Fuente de verdad en el próximo `apply` |
| `config_nonsensitive` | Propiedades del conector. `kafka.service.account.id` se inyecta desde `vault.service_account` |
| `vault.service_account` | Display name del SA (debe existir). Kafka y Schema Registry usan **este mismo** SA |
| `vault.api-key` | Nombre lógico del API key de cluster en Vault (`AK_AZC_...`). Inventario; el conector corre con `SERVICE_ACCOUNT`, no inyecta `kafka.api.key` |
| `vault.secrets` | Mapa `config_key → { path, field }` en Vault. El workflow los lee e inyecta como `config_sensitive` |

Si hay `errors.tolerance` y un topic (`topics` o `kafka.topic`), el módulo asigna `errors.deadletterqueue.topic.name` = `{primer-topic}-dlq`. Ese topic tiene que existir de antemano.

Path de Vault: se admite `{mount}/data/...`; el workflow lo traduce a `{mount}/kv2/data/...` si hace falta.

---

## YAML de RBAC (`security/`)

Mismo schema que Flink v2 (`cluster.cc.rbac`). Este módulo aplica **topic**, **subject** y **transactional-id**. Ignora `compute-pool` / `FlinkDeveloper`.

El `principal` debe coincidir con `vault.service_account` del conector.

```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_PEVE_BLOB_01
      resources:
      - resource_type: subject
        resource_name: 'azc-peve-connect-test-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      - resource_type: topic
        resource_name: 'azc-peve-connect-test'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      - resource_type: topic
        resource_name: 'azc-peve-connect-test-dlq'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
        - operation: DeveloperRead
```

Roles típicos: [CONNECTOR_DLQ_PERMISSIONS.md](./CONNECTOR_DLQ_PERMISSIONS.md).

Borrar un YAML de `connects/` **no** quita estos bindings. Hay que editar o borrar el YAML de `security/` y hacer `apply`.

---

## Nomenclatura

| Qué | Formato | Ejemplo |
|---|---|---|
| CODAPP | 4 letras | `PEVE` |
| Use-case (carpeta e input) | kebab-case estable | `use-case-name-01` |
| Archivo del conector | `ccloud-{tipo}-{secuencia}.yaml` | `ccloud-azure-blob-storage-sink-connector-01.yaml` |
| `name` en Cloud | sin prefijo de entorno | `peve-azure-blob-storage-sink-connector-01` |
| Service Account | el que entregue el alta | `SA_AZC_DES_PEVE_BLOB_01` |
| API key (inventario) | un AK de cluster por SA; no uno para topic y otro para SR | `AK_AZC_DES_PEVE_BLOB_01` |
| `status` | `RUNNING` o `PAUSED` | `RUNNING` |

---

## Ciclo de vida

### Alta (nuevo conector o use-case nuevo)

1. SA, topics y DLQ listos; secretos en Vault.
2. Crear `{use-case}/connects/{connector}.yaml` y bindings en `security/`.
3. Workflow: `action: plan`, luego `apply`, con `CODAPP` y `use_case`.

### Cambio de configuración

1. Editar el YAML en `connects/` (o `security/`).
2. `plan` + `apply` del mismo `use_case`.

### Agregar un conector a un use-case que ya está desplegado

1. Añade un YAML nuevo en `connects/` (nombre de archivo **nuevo**).
2. Completa RBAC en `security/` si aplica.
3. `apply` del mismo `use_case`.

Terraform crea **solo** el nuevo. Los demás no se recrean ni pierden offsets.

### Quitar un conector del use-case

1. Borra **ese** YAML de `connects/` (no renombres: borra).
2. Quita las entradas de `security/` que ya no apliquen.
3. `apply` del mismo `use_case`.

Se destruye **solo** ese conector. Los otros siguen.

No vacíes `connects/` para “limpiar”: un `apply` sin YAML se **bloquea**. Para borrar el use-case entero usa `destroy`.

### Pausar / reanudar un conector

**Desde el Action (operación puntual):**

1. `action: pause` o `resume`.
2. Mismo `CODAPP` + `use_case`.
3. **`connector`**: nombre del archivo sin `.yaml`.

Eso no modifica el YAML. El próximo **`apply` vuelve al `status` del archivo**. Si el pause debe quedar fijo, pon `status: "PAUSED"` en el YAML y haz `apply`.

**Desde Git (estado permanente):** cambia `status` en el YAML y `apply`.

### Borrar el use-case entero

`action: destroy` con `CODAPP` + `use_case`. Elimina conectores y RBAC de ese módulo.

---

## Reglas que evitan recrear el conector

| Hacer | No hacer |
|---|---|
| Agregar un YAML con **nombre de archivo nuevo** | Renombrar un YAML ya aplicado |
| Borrar el YAML para dar de baja | Cambiar `name` / `config_nonsensitive.name` después del primer apply |
| Editar propiedades dentro del mismo archivo | Vaciar `connects/` y hacer `apply` |

Renombrar el archivo o el `name` cambia la key de Terraform: destruye el conector viejo, crea uno nuevo y **se pierden los offsets**.

---

## Cómo disparar el workflow

1. Actions → el workflow de conectores → **Run workflow**.
2. Rellenar:

| Input | `plan` / `apply` / `destroy` | `pause` / `resume` |
|---|---|---|
| `action` | la acción | `pause` o `resume` |
| `CODAPP` | sí | sí |
| `use_case` | sí (carpeta del caso de uso) | sí |
| `connector` | no (se ignora) | **obligatorio** |

Hoy el workflow apunta a **DES** (`{CODAPP}/desa/{use_case}/`).

---

## Troubleshooting

**`connects/` no existe o sin YAML**  
El `apply` se bloquea a propósito: un directorio vacío destruiría todos los conectores del use-case. Añade al menos un YAML o usa `destroy`.

**`security/` no existe**  
El job falla. No se “omite” RBAC en silencio (un for_each vacío borraría los bindings). Crea la carpeta.

**pause/resume: falta `connector` o no existe el YAML**  
El input debe ser el basename de un archivo en `connects/` de ese use-case.

**El conector pausado volvió a RUNNING**  
El `apply` restauró el `status` del YAML. Deja `status: "PAUSED"` en el archivo si debe persistir.

**Credenciales rechazadas (Azure, SQL, etc.)**  
Revisa `vault.secrets` (`path` + `field`). No pongas el secreto en el YAML.

**RBAC / DLQ**  
El SA necesita Read en el topic (sink) o Write (source), y Write en `{topic}-dlq`. Ver [CONNECTOR_DLQ_PERMISSIONS.md](./CONNECTOR_DLQ_PERMISSIONS.md).

---

## Referencias

- [Confluent Cloud Connectors](https://docs.confluent.io/cloud/current/connectors/index.html)
- [Terraform `confluent_connector`](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/connector)
- [Permisos RBAC y DLQ](./CONNECTOR_DLQ_PERMISSIONS.md)

## Changelog

- **2026-08-20**: Modelo por use-case (`connects/` + `security/`). Despliegue por `use_case`; `pause`/`resume` por conector. Se retira el layout `ccloud-connectors/{connector}/{env}-*.json`.
