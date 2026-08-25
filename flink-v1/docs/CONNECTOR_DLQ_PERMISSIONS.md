# Permisos RBAC Requeridos para Conectores

## Resumen

Los conectores full-managed de Confluent Cloud **requieren permisos RBAC** en los topics que utilizan (source, sink y DLQ). Estos permisos se otorgan al **Service Account** del conector **antes** (o en el mismo `apply`) del despliegue.

El RBAC **no** va en el YAML del conector (`connects/`). Se declara en archivos YAML dentro de `{CODAPP}/{desa|cert|prod}/{use-case}/security/*.yaml` usando el formato estructurado definido en este documento.

Ver [CONNECTORS_OPERATIONAL_MODEL.md](./CONNECTORS_OPERATIONAL_MODEL.md) para el modelo operativo completo.

> **Nota**: Confluent Cloud Dedicated (RBAC, no ACLs).

## Formato de Declaración RBAC

Los permisos RBAC se declaran en archivos YAML con la siguiente estructura:

```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_NOMBRE_SERVICE_ACCOUNT
      resources:
      - resource_type: [topic|subject|group|transactional-id]
        resource_name: 'nombre-del-recurso'
        pattern_type: [LITERAL|PREFIXED]
        role:
        - operation: [DeveloperRead|DeveloperWrite|DeveloperManage|ResourceOwner]
```

| Campo | Descripción |
|-------|-------------|
| `principal` | Display name del Service Account (debe coincidir con `vault.service_account` del conector) |
| `resource_type` | Tipo de recurso: `topic`, `subject`, `group`, `transactional-id` |
| `resource_name` | Nombre del recurso (topic, subject, consumer group, etc.) |
| `pattern_type` | `LITERAL` (nombre exacto) o `PREFIXED` (prefijo del nombre) |
| `operation` | Operación RBAC permitida: `DeveloperRead`, `DeveloperWrite`, `DeveloperManage`, `ResourceOwner` |

## Prerequisitos: Roles RBAC Requeridos

Antes de desplegar cualquier conector, el Service Account debe tener los siguientes roles RBAC declarados en el archivo `security/*.yaml` del use-case:

### Para Conectores Sink (ej: PostgresSink, AzureBlobStorageSink)

| Recurso | Operación Requerida | Descripción |
|---------|---------------------|-------------|
| **Topic de entrada** (`topics`) | `DeveloperRead` | Leer mensajes del topic de entrada |
| **Subject de entrada** (Schema Registry) | `DeveloperRead` | Leer el schema Avro del topic de entrada |
| **Topic DLQ** (`[topic]-dlq`) | `DeveloperWrite` + `DeveloperRead` | Escribir mensajes fallidos al DLQ |
| **Consumer Group** (`connect-lcc-`) | `ResourceOwner` (PREFIXED) | Gestionar el consumer group del conector |

**Ejemplo YAML para Sink Connector:**

```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_PEVE_PGSNK_01
      resources:
      # Schema Registry - lectura del schema del topic de entrada
      - resource_type: subject
        resource_name: 'azc-peve-transaction-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      # Topic de entrada - lectura de mensajes
      - resource_type: topic
        resource_name: 'azc-peve-transaction'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      # Topic DLQ - escritura de mensajes fallidos
      - resource_type: topic
        resource_name: 'azc-peve-transaction-dlq'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
        - operation: DeveloperRead
      # Consumer Group - requerido para todos los sink connectors
      - resource_type: group
        resource_name: 'connect-lcc-'
        pattern_type: PREFIXED
        role:
        - operation: ResourceOwner
```

### Para Conectores Source (ej: DatagenSource, AzureEventHubsSource)

| Recurso | Operación Requerida | Descripción |
|---------|---------------------|-------------|
| **Topic de salida** (`kafka.topic`) | `DeveloperWrite` | Escribir mensajes al topic de salida |
| **Subject de salida** (Schema Registry) | `DeveloperWrite` | Registrar el schema Avro del topic de salida |
| **Topic DLQ** (`[topic]-dlq`) | `DeveloperWrite` | Escribir mensajes fallidos al DLQ (si aplica) |

**Ejemplo YAML para Source Connector:**

```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_PEVE_DATAGEN_01
      resources:
      # Schema Registry - escritura del schema del topic de salida
      - resource_type: subject
        resource_name: 'azc-peve-transaction-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
      # Topic de salida - escritura de mensajes
      - resource_type: topic
        resource_name: 'azc-peve-transaction'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
      # Topic DLQ - escritura de mensajes fallidos (opcional, si el conector lo soporta)
      # - resource_type: topic
      #   resource_name: 'azc-peve-transaction-dlq'
      #   pattern_type: LITERAL
      #   role:
      #   - operation: DeveloperWrite
```

### Resumen de Operaciones RBAC

| Operación | Permisos | Uso Recomendado |
|-----------|----------|-----------------|
| `ResourceOwner` | Lectura y escritura completas | Para consumer groups (`connect-lcc-`) en sink connectors |
| `DeveloperRead` | Solo lectura | Para topics de entrada y subjects en sinks |
| `DeveloperWrite` | Solo escritura | Para topics de salida, DLQ y subjects en sources |
| `DeveloperManage` | Gestión de recursos | Para operaciones avanzadas de administración |

### Permisos de Schema Registry

Los conectores que utilizan schemas Avro (configurados con `input.data.format: "AVRO"` o `output.data.format: "AVRO"`) necesan permisos en **subjects** de Schema Registry para:

1. **Leer schemas existentes** de los topics de entrada (sinks): `DeveloperRead` en el subject
2. **Registrar nuevos schemas** cuando escriben a topics de salida o DLQ (sources): `DeveloperWrite` en el subject
3. **Gestionar versiones de schemas** para los subjects correspondientes a los topics

**Formato del subject**: `{topic-name}-value` (ej: `azc-peve-transaction-value`)

**Nota**: Los permisos de Schema Registry se declaran a nivel de **subject** (no a nivel de environment como en comandos CLI). Cada topic tiene su propio subject que debe declararse explícitamente en el YAML de seguridad.

## Service Account y Permisos

### 1. Service Account del Conector

Cada conector utiliza el Service Account configurado en la sección `vault` del YAML:

```yaml
vault:
  service_account: "SA_AZC_DES_PEVE_PGSNK_01"
  secrets:
    connection.password:
      path: "peve/data/dev/peve/postgresql/DB_PEVE_CONNECT_DEV"
      field: "password"
```

El `service_account` especificado aquí es el que Terraform inyecta automáticamente como `kafka.service.account.id` en la configuración del conector.

**⚠️ IMPORTANTE**: Los permisos RBAC se otorgan al Service Account **ANTES** del despliegue del conector, declarándolos en el archivo `security/*.yaml` del mismo use-case. **NO se configuran en el YAML del conector**.

### 2. Permisos Requeridos para DLQ (RBAC)

En Confluent Cloud dedicado, los permisos se gestionan mediante **RBAC (Role-Based Access Control)**. El Service Account del conector necesita permisos declarados en el archivo YAML de seguridad que le otorguen acceso de escritura al topic DLQ.

> **Nota**: Además de los permisos del DLQ, el Service Account también necesita permisos en los topics source/sink y subjects de Schema Registry. Ver la sección [Prerequisitos](#prerequisitos-roles-rbac-requeridos) arriba.

#### Permisos Típicos para DLQ:

**Para Sink Connectors:**
```yaml
- resource_type: topic
  resource_name: 'azc-peve-transaction-dlq'
  pattern_type: LITERAL
  role:
  - operation: DeveloperWrite
  - operation: DeveloperRead
```

**Para Source Connectors (si el conector soporta DLQ):**
```yaml
- resource_type: topic
  resource_name: 'azc-peve-transaction-dlq'
  pattern_type: LITERAL
  role:
  - operation: DeveloperWrite
```

**Nota**: `DeveloperRead` en el DLQ es útil para monitoreo pero no es estrictamente necesario. `DeveloperWrite` es obligatorio para que el conector pueda enviar mensajes fallidos al DLQ.

### 3. ¿Se Necesita un API Key Adicional?

**NO**, no se requiere un API Key adicional para el DLQ. Los conectores full-managed de Confluent Cloud:

1. **Usan el Service Account configurado** (`vault.service_account`)
2. **Confluent Cloud gestiona automáticamente** la autenticación del conector mediante el parámetro `kafka.auth.mode: "SERVICE_ACCOUNT"`
3. **Solo necesitas declarar permisos RBAC** al Service Account en el archivo YAML de seguridad

### 4. Proceso de Configuración Completo

#### Paso 1: Crear los Topics
Todos los topics (source, sink y DLQ) deben crearse previamente por otro proceso externo.

**Para Sink Connectors:**
- Topic de entrada: `azc-peve-transaction` (configurado en `topics` del YAML)
- Topic DLQ: `azc-peve-transaction-dlq` (generado automáticamente si `errors.tolerance` está configurado)

**Para Source Connectors:**
- Topic de salida: `azc-peve-transaction` (configurado en `kafka.topic` del YAML)
- Topic DLQ: `azc-peve-transaction-dlq` (generado automáticamente si el conector lo soporta)

#### Paso 2: Crear el archivo YAML del conector

En `{CODAPP}/{desa|cert|prod}/{use-case}/connects/{connector-name}.yaml`:

**Ejemplo Sink Connector (PostgreSQL):**
```yaml
name: "peve-postgresql-sink-connector-01"
status: "RUNNING"

config_nonsensitive:
  name: "peve-postgresql-sink-connector-01"
  connector.class: "PostgresSink"
  kafka.auth.mode: "SERVICE_ACCOUNT"
  input.data.format: "AVRO"
  insert.mode: "INSERT"
  auto.create: "true"
  auto.evolve: "true"
  tasks.max: "1"
  errors.tolerance: "all"
  topics: "azc-peve-transaction"
  connection.host: "peved02server.postgres.database.azure.com"
  connection.port: "5432"
  db.name: "postgres"

config_sensitive:
  connection.user: "USREJDBCONNECTDES"
  connection.password: "CHANGE_ME"

vault:
  service_account: "SA_AZC_DES_PEVE_PGSNK_01"
```

**Ejemplo Source Connector (Datagen):**
```yaml
name: "peve-datagen-source-connector-01"
status: "RUNNING"

config_nonsensitive:
  name: "peve-datagen-source-connector-01"
  connector.class: "DatagenSource"
  kafka.auth.mode: "SERVICE_ACCOUNT"
  schema.context.name: "default"
  kafka.topic: "azc-peve-transaction"
  output.data.format: "AVRO"
  quickstart: "TRANSACTIONS"
  max.interval: "1000"
  iterations: "10000000"
  tasks.max: "1"

vault:
  service_account: "SA_AZC_DES_PEVE_DATAGEN_01"
```

#### Paso 3: Declarar Permisos RBAC en el archivo de seguridad

En `{CODAPP}/{desa|cert|prod}/{use-case}/security/cc-azure_eu2_kafka01-rbac-des.yaml`:

**Para Sink Connector:**
```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_PEVE_PGSNK_01
      resources:
      # Schema Registry - lectura del schema del topic de entrada
      - resource_type: subject
        resource_name: 'azc-peve-transaction-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      # Topic de entrada - lectura de mensajes
      - resource_type: topic
        resource_name: 'azc-peve-transaction'
        pattern_type: LITERAL
        role:
        - operation: DeveloperRead
      # Topic DLQ - escritura de mensajes fallidos
      - resource_type: topic
        resource_name: 'azc-peve-transaction-dlq'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
        - operation: DeveloperRead
      # Consumer Group - requerido para todos los sink connectors
      - resource_type: group
        resource_name: 'connect-lcc-'
        pattern_type: PREFIXED
        role:
        - operation: ResourceOwner
```

**Para Source Connector:**
```yaml
cluster:
  cc:
    properties:
      - name: "azure_eu2_kafka01"
    rbac:
    - principal: SA_AZC_DES_PEVE_DATAGEN_01
      resources:
      # Schema Registry - escritura del schema del topic de salida
      - resource_type: subject
        resource_name: 'azc-peve-transaction-value'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
      # Topic de salida - escritura de mensajes
      - resource_type: topic
        resource_name: 'azc-peve-transaction'
        pattern_type: LITERAL
        role:
        - operation: DeveloperWrite
```

#### Paso 4: Desplegar el Conector

Una vez que:
1. ✅ Todos los topics existen (source/sink y DLQ)
2. ✅ El archivo YAML del conector está en `connects/`
3. ✅ Los permisos RBAC están declarados en `security/`
4. ✅ Los secretos están en HashiCorp Vault (si aplica)

Ejecutar el workflow de GitHub Actions con:
- `action: plan` (para revisar cambios)
- `action: apply` (para desplegar)
- `CODAPP`: código de la aplicación (ej: `PEVE`)
- `use_case`: nombre del caso de uso (ej: `use-case-name-02`)

### 5. Verificación de Permisos RBAC

Para verificar que el Service Account tiene los permisos RBAC correctos usando el CLI de Confluent:

```bash
# Listar role bindings del Service Account
confluent iam rbac role-binding list \
  --principal User:sa-xxxxx \
  --environment env-xxxxx
```

Deberías ver entradas como:
```
Principal      | Role          | Resource Type | Resource Name               | Pattern Type
User:sa-xxxxx  | DeveloperRead | Topic         | azc-peve-transaction        | LITERAL
User:sa-xxxxx  | DeveloperWrite| Topic         | azc-peve-transaction-dlq    | LITERAL
User:sa-xxxxx  | ResourceOwner | Group         | connect-lcc-                | PREFIXED
```

### 6. Consideraciones Importantes

1. **Los permisos RBAC NO se configuran en el YAML del conector** - Se declaran en el archivo `security/*.yaml` del mismo use-case antes del despliegue
2. **Todos los topics deben existir antes** de desplegar el conector (source, sink y DLQ)
3. **Los permisos RBAC se declaran en formato YAML** - Ver ejemplos en las secciones anteriores
4. **El mismo Service Account** declarado en `vault.service_account` es el que necesita los permisos RBAC
5. **No se requiere API Key adicional** - Confluent Cloud gestiona la autenticación automáticamente con `kafka.auth.mode: "SERVICE_ACCOUNT"`
6. **RBAC es obligatorio en Confluent Cloud dedicado** - No se pueden usar ACLs
7. **El `principal` debe coincidir exactamente** con el `vault.service_account` del conector
8. **El YAML del conector solo contiene configuración** - Nombres de topics, formatos, etc., pero NO permisos
9. **Los sink connectors SIEMPRE necesitan** el permiso `ResourceOwner` PREFIXED en el consumer group `connect-lcc-`
10. **Los permisos de subjects son a nivel de subject individual** - No se declaran a nivel de environment

### 7. Estructura de Directorios y Despliegue

Los conectores y sus permisos RBAC se organizan por caso de uso:

```
{CODAPP}/
├── desa/
│   └── {use-case}/
│       ├── connects/
│       │   └── {connector-name}.yaml     # Configuración del conector
│       └── security/
│           └── cc-azure_eu2_kafka01-rbac-des.yaml  # Permisos RBAC
├── cert/
│   └── {use-case}/
│       ├── connects/
│       └── security/
└── prod/
    └── {use-case}/
        ├── connects/
        └── security/
```

**Proceso de despliegue:**
1. Crear el archivo YAML del conector en `connects/`
2. Declarar los permisos RBAC en `security/`
3. Ejecutar workflow con `action: plan` para revisar
4. Ejecutar workflow con `action: apply` para desplegar

**Nota**: El `plan` y `apply` se ejecutan por **use-case completo**, no por conector individual. Terraform aplica todos los conectores y permisos RBAC declarados en los archivos YAML del use-case.

## Resumen de Respuesta

**¿Los permisos RBAC se configuran en el YAML del conector?**
- ❌ **NO** - Los permisos RBAC se declaran en el archivo `security/*.yaml` del use-case, **NO** en el YAML del conector en `connects/`

**¿Dónde se declaran los permisos RBAC?**
- ✅ En archivos YAML dentro de `{CODAPP}/{desa|cert|prod}/{use-case}/security/*.yaml`
- ✅ Usando el formato estructurado: `principal`, `resources`, `resource_type`, `pattern_type`, `role`, `operation`
- ✅ Se aplican mediante el workflow de GitHub Actions junto con el conector

**¿El conector necesita un API Key adicional?**
- ❌ **NO** - No se requiere API Key adicional. El conector usa el Service Account configurado en `vault.service_account`

**¿El conector necesita permisos RBAC en los topics?**
- ✅ **SÍ** - El Service Account necesita operaciones RBAC en:
  - **Sink Connectors**: 
    - `DeveloperRead` en topic de entrada
    - `DeveloperRead` en subject de entrada
    - `DeveloperWrite` + `DeveloperRead` en topic DLQ
    - `ResourceOwner` PREFIXED en consumer group `connect-lcc-`
  - **Source Connectors**: 
    - `DeveloperWrite` en topic de salida
    - `DeveloperWrite` en subject de salida
    - `DeveloperWrite` en topic DLQ (si aplica)

**¿Cómo se otorgan los permisos?**
- Mediante archivos YAML declarativos en la carpeta `security/`
- Los permisos se aplican automáticamente mediante Terraform cuando se ejecuta el workflow
- Opcionalmente, también se pueden gestionar manualmente con el comando `confluent iam rbac role-binding create`

**¿Por qué RBAC y no ACLs?**
- En **Confluent Cloud dedicado**, RBAC es el método obligatorio de control de acceso
- RBAC proporciona mayor granularidad y mejor gestión de permisos a nivel de organización

**¿Qué pasa con el topic DLQ?**
- El topic DLQ se nombra automáticamente como `{topic}-dlq` cuando el conector tiene `errors.tolerance` configurado
- El topic DLQ **debe ser creado manualmente** antes del despliegue (Terraform no lo crea automáticamente)
- El conector necesita permisos de escritura (`DeveloperWrite`) en el topic DLQ

## Checklist de Prerequisitos

Antes de desplegar un conector, verifica:

### Recursos Previos
- [ ] Service Account creado (el nombre va en `vault.service_account`)
- [ ] Todos los topics creados (source/sink y DLQ con sufijo `-dlq`)
- [ ] Secretos almacenados en HashiCorp Vault (si el conector necesita credenciales)

### Archivos YAML Preparados
- [ ] Archivo del conector creado en `{CODAPP}/{desa|cert|prod}/{use-case}/connects/{connector-name}.yaml`
  - [ ] Campo `vault.service_account` configurado
  - [ ] Campo `kafka.auth.mode: "SERVICE_ACCOUNT"` configurado
  - [ ] Campo `errors.tolerance: "all"` configurado (si se requiere DLQ)
  - [ ] Formato de datos configurado (`input.data.format` / `output.data.format`)
  - [ ] Campo `schema.context.name: "default"` configurado (si usa Avro)

### Permisos RBAC Declarados en `security/*.yaml`

**Para Sink Connectors:**
- [ ] `DeveloperRead` en subject del topic de entrada (`{topic-name}-value`)
- [ ] `DeveloperRead` en topic de entrada
- [ ] `DeveloperWrite` + `DeveloperRead` en topic DLQ (`{topic-name}-dlq`)
- [ ] `ResourceOwner` PREFIXED en consumer group (`connect-lcc-`)

**Para Source Connectors:**
- [ ] `DeveloperWrite` en subject del topic de salida (`{topic-name}-value`)
- [ ] `DeveloperWrite` en topic de salida
- [ ] `DeveloperWrite` en topic DLQ (si el conector lo soporta)

### Validación
- [ ] El `principal` en `security/*.yaml` coincide exactamente con `vault.service_account` del conector
- [ ] Los nombres de topics en el YAML de seguridad coinciden con los del YAML del conector
- [ ] La carpeta `security/` existe (incluso si está vacía)

### Despliegue
- [ ] Ejecutar workflow con `action: plan` para revisar cambios
- [ ] Ejecutar workflow con `action: apply` para desplegar
- [ ] Especificar `CODAPP` y `use_case` correctos

## Referencias Adicionales

### Formato del Subject en Schema Registry

Para topics que usan Avro, el subject sigue el formato:
- **Key subject**: `{topic-name}-key` (raramente usado en conectores)
- **Value subject**: `{topic-name}-value` (más común)

Ejemplo: para el topic `azc-peve-transaction`, el subject es `azc-peve-transaction-value`.

### Consumer Group de Sink Connectors

Los sink connectors crean automáticamente un consumer group con el formato `connect-lcc-{connector-id}`. Por eso necesitan el permiso `ResourceOwner` PREFIXED en `connect-lcc-` para poder:
- Leer mensajes (READ)
- Describir el grupo (DESCRIBE)
- Gestionar offsets (DELETE)

### Nomenclatura de Topics DLQ

Cuando el conector tiene `errors.tolerance` configurado, el sistema asigna automáticamente:
- `errors.deadletterqueue.topic.name = {primer-topic}-dlq`

Para un sink con `topics: "azc-peve-transaction"`, el DLQ será `azc-peve-transaction-dlq`.
Para un source con `kafka.topic: "azc-peve-transaction"`, el DLQ será `azc-peve-transaction-dlq`.

