# Permisos RBAC Requeridos para Conectores

## Resumen

Los conectores full-managed de Confluent Cloud **requieren permisos RBAC** en los topics que utilizan (source, sink y DLQ). Estos permisos se otorgan mediante **RBAC (Role-Based Access Control)** al **Service Account** configurado en el conector **ANTES** del despliegue. Los permisos RBAC **NO se configuran en el JSON del conector**.

> **Nota**: Este documento asume que los conectores se desplegarán en **Confluent Cloud dedicado**, por lo que se utiliza **RBAC** en lugar de ACLs.

> **Importante**: Los permisos RBAC se otorgan al Service Account, **NO** se configuran en el archivo JSON del conector. El JSON solo contiene la configuración del conector (nombres de topics, formatos, etc.).

## Prerequisitos: Roles RBAC Requeridos

Antes de desplegar cualquier conector, el Service Account debe tener los siguientes roles RBAC:

### Para Conectores Sink (ej: MicrosoftSqlserverSink, AzureBlobStorageSink)

| Recurso | Rol Requerido | Operación | Descripción |
|---------|---------------|-----------|-------------|
| **Topics de entrada** (`topics`) | `DeveloperRead` o `ResourceOwner` | READ | Leer mensajes de los topics de entrada |
| **Topic DLQ** (`[topic]-dlq`) | `DeveloperWrite` o `ResourceOwner` | WRITE | Escribir mensajes fallidos al DLQ |
| **Schema Registry** | `DeveloperWrite` o `ResourceOwner` | READ/WRITE | Leer y escribir schemas Avro para topics normales y DLQ |

**Ejemplo de comandos:**
```bash
# Permiso de lectura en topics de entrada
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperRead \
  --resource Topic:poc-peve-badi-01 \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx

# Permiso de escritura en DLQ
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource Topic:poc-peve-badi-01-dlq \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx

# Permiso en Schema Registry (para schemas Avro)
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource SchemaRegistry:env-xxxxx \
  --environment env-xxxxx
```

### Para Conectores Source (ej: AzureEventHubsSource, IbmMQSource)

| Recurso | Rol Requerido | Operación | Descripción |
|---------|---------------|-----------|-------------|
| **Topic de salida** (`kafka.topic`) | `DeveloperWrite` o `ResourceOwner` | WRITE | Escribir mensajes al topic de salida |
| **Topic DLQ** (`[topic]-dlq`) | `DeveloperWrite` o `ResourceOwner` | WRITE | Escribir mensajes fallidos al DLQ |
| **Schema Registry** | `DeveloperWrite` o `ResourceOwner` | READ/WRITE | Leer y escribir schemas Avro para topics normales y DLQ |

**Ejemplo de comandos:**
```bash
# Permiso de escritura en topic de salida
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource Topic:dev-topic-name \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx

# Permiso de escritura en DLQ
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource Topic:dev-topic-name-dlq \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx

# Permiso en Schema Registry (para schemas Avro)
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource SchemaRegistry:env-xxxxx \
  --environment env-xxxxx
```

### Resumen de Roles RBAC

| Rol | Permisos | Uso Recomendado |
|-----|----------|-----------------|
| `ResourceOwner` | Lectura y escritura completas | Cuando necesitas permisos completos |
| `DeveloperRead` | Solo lectura | Para topics de entrada en sinks |
| `DeveloperWrite` | Solo escritura | Para topics de salida, DLQ y Schema Registry |

### Permisos de Schema Registry

Los conectores que utilizan schemas Avro (configurados con `input.data.format: "JSON_SR"` o `output.data.format: "JSON_SR"`) necesitan permisos en Schema Registry para:

1. **Leer schemas existentes** de los topics de entrada (sinks) o para validar schemas
2. **Registrar nuevos schemas** cuando escriben a topics de salida o DLQ
3. **Gestionar versiones de schemas** para los subjects correspondientes a los topics

**Rol recomendado**: `DeveloperWrite` o `ResourceOwner` en Schema Registry a nivel de Environment.

**Nota**: El formato del recurso para Schema Registry es `SchemaRegistry:env-xxxxx` (a nivel de environment, no de cluster).

## Service Account y Permisos

### 1. Service Account del Conector

Cada conector utiliza el Service Account configurado en:
```json
{
  "config_nonsensitive": {
    "kafka.service.account.id": "sa-xxxxx"
  }
}
```

Este Service Account es el que se pasa como variable `principal_id` en Terraform.

**⚠️ IMPORTANTE**: Los permisos RBAC se otorgan al Service Account **ANTES** del despliegue del conector. **NO se configuran en el JSON del conector**.

### 2. Permisos Requeridos para DLQ (RBAC)

En Confluent Cloud dedicado, los permisos se gestionan mediante **RBAC (Role-Based Access Control)**. El Service Account del conector necesita un **rol RBAC** que le otorgue permisos de escritura al topic DLQ.

> **Nota**: Además de los permisos del DLQ, el Service Account también necesita permisos en los topics source/sink. Ver la sección [Prerequisitos](#prerequisitos-roles-rbac-requeridos) arriba.

#### Rol Recomendado:
- **Rol**: `ResourceOwner` o `DeveloperWrite`
- **Recurso**: Topic DLQ (formato: `[nombre-topic]-dlq`)
- **Scope**: Cluster específico o Environment

#### Opción 1: Rol `ResourceOwner` (Recomendado)
Otorga permisos completos de lectura y escritura al topic DLQ:

```bash
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role ResourceOwner \
  --resource Topic:poc-peve-badi-01-dlq \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx
```

#### Opción 2: Rol `DeveloperWrite` (Más restrictivo)
Otorga solo permisos de escritura al topic DLQ:

```bash
confluent iam rbac role-binding create \
  --principal User:sa-xxxxx \
  --role DeveloperWrite \
  --resource Topic:poc-peve-badi-01-dlq \
  --kafka-cluster lkc-xxxxx \
  --environment env-xxxxx
```

### 3. ¿Se Necesita un API Key Adicional?

**NO**, no se requiere un API Key adicional para el DLQ. Los conectores full-managed de Confluent Cloud:

1. **Usan el Service Account configurado** (`kafka.service.account.id`)
2. **Confluent Cloud gestiona automáticamente** la autenticación del conector
3. **Solo necesitas otorgar permisos RBAC** al Service Account en el topic DLQ mediante roles

### 4. Proceso de Configuración Completo

#### Paso 1: Crear los Topics
Todos los topics (source, sink y DLQ) deben crearse previamente por otro proceso externo.

**Para Sink Connectors:**
- Topic de entrada: `poc-peve-badi-01` (configurado en `topics` del JSON)
- Topic DLQ: `poc-peve-badi-01-dlq` (generado automáticamente)

**Para Source Connectors:**
- Topic de salida: `dev-topic-name` (configurado en `kafka.topic` del JSON)
- Topic DLQ: `dev-topic-name-dlq` (generado automáticamente)

#### Paso 2: Otorgar Permisos RBAC al Service Account

**Para Sink Connectors:**
```bash
SERVICE_ACCOUNT_ID="sa-xxxxx"
KAFKA_CLUSTER_ID="lkc-xxxxx"
ENVIRONMENT_ID="env-xxxxx"
INPUT_TOPIC="poc-peve-badi-01"
DLQ_TOPIC="${INPUT_TOPIC}-dlq"

# 1. Permiso de lectura en topic de entrada
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperRead \
  --resource Topic:$INPUT_TOPIC \
  --kafka-cluster $KAFKA_CLUSTER_ID \
  --environment $ENVIRONMENT_ID

# 2. Permiso de escritura en DLQ
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperWrite \
  --resource Topic:$DLQ_TOPIC \
  --kafka-cluster $KAFKA_CLUSTER_ID \
  --environment $ENVIRONMENT_ID

# 3. Permiso en Schema Registry (para schemas Avro)
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperWrite \
  --resource SchemaRegistry:$ENVIRONMENT_ID \
  --environment $ENVIRONMENT_ID
```

**Para Source Connectors:**
```bash
SERVICE_ACCOUNT_ID="sa-xxxxx"
KAFKA_CLUSTER_ID="lkc-xxxxx"
ENVIRONMENT_ID="env-xxxxx"
OUTPUT_TOPIC="dev-topic-name"
DLQ_TOPIC="${OUTPUT_TOPIC}-dlq"

# 1. Permiso de escritura en topic de salida
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperWrite \
  --resource Topic:$OUTPUT_TOPIC \
  --kafka-cluster $KAFKA_CLUSTER_ID \
  --environment $ENVIRONMENT_ID

# 2. Permiso de escritura en DLQ
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperWrite \
  --resource Topic:$DLQ_TOPIC \
  --kafka-cluster $KAFKA_CLUSTER_ID \
  --environment $ENVIRONMENT_ID

# 3. Permiso en Schema Registry (para schemas Avro)
confluent iam rbac role-binding create \
  --principal User:$SERVICE_ACCOUNT_ID \
  --role DeveloperWrite \
  --resource SchemaRegistry:$ENVIRONMENT_ID \
  --environment $ENVIRONMENT_ID
```

#### Paso 3: Desplegar el Conector
Una vez que:
1. ✅ Todos los topics existen (source/sink y DLQ)
2. ✅ El Service Account tiene todos los permisos RBAC necesarios
3. ✅ El JSON del conector está configurado correctamente

El conector puede desplegarse normalmente mediante Terraform.

### 5. Verificación de Permisos RBAC

Para verificar que el Service Account tiene los permisos RBAC correctos:

```bash
# Listar role bindings del Service Account
confluent iam rbac role-binding list \
  --principal User:sa-xxxxx \
  --environment env-xxxxx
```

Deberías ver una entrada como:
```
Principal      | Role          | Resource Type | Resource Name        | Pattern Type
User:sa-xxxxx  | ResourceOwner | Topic         | poc-peve-badi-01-dlq | LITERAL
```

O si usaste `DeveloperWrite`:
```
Principal      | Role          | Resource Type | Resource Name        | Pattern Type
User:sa-xxxxx  | DeveloperWrite| Topic         | poc-peve-badi-01-dlq | LITERAL
```

### 6. Consideraciones Importantes

1. **Los permisos RBAC NO se configuran en el JSON del conector** - Se otorgan al Service Account antes del despliegue
2. **Todos los topics deben existir antes** de desplegar el conector (source, sink y DLQ)
3. **Los permisos RBAC deben otorgarse antes** del despliegue
4. **El mismo Service Account** usado en `kafka.service.account.id` es el que necesita permisos
5. **No se requiere API Key adicional** - Confluent Cloud gestiona la autenticación automáticamente
6. **RBAC es obligatorio en Confluent Cloud dedicado** - No se pueden usar ACLs
7. **El formato del principal es `User:sa-xxxxx`** - Incluye el prefijo `User:`
8. **El JSON del conector solo contiene configuración** - Nombres de topics, formatos, etc., pero NO permisos

### 7. Automatización con Terraform (Opcional)

Si deseas automatizar la creación de role bindings RBAC, puedes usar el recurso `confluent_rbac_role_binding`:

```hcl
# Para Sink Connector - Permiso de lectura en topic de entrada
resource "confluent_rbac_role_binding" "input_topic_read" {
  principal   = "User:${var.principal_id}"
  role_name   = "DeveloperRead"
  
  crn_pattern = "crn://confluent.cloud/kafka=${var.kafka_cluster_id}/topic=[nombre-topic-entrada]"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Permiso de escritura en DLQ
resource "confluent_rbac_role_binding" "dlq_write" {
  principal   = "User:${var.principal_id}"
  role_name   = "DeveloperWrite"
  
  crn_pattern = "crn://confluent.cloud/kafka=${var.kafka_cluster_id}/topic=[nombre-topic]-dlq"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Para Source Connector - Permiso de escritura en topic de salida
resource "confluent_rbac_role_binding" "output_topic_write" {
  principal   = "User:${var.principal_id}"
  role_name   = "DeveloperWrite"
  
  crn_pattern = "crn://confluent.cloud/kafka=${var.kafka_cluster_id}/topic=[nombre-topic-salida]"
  
  lifecycle {
    prevent_destroy = false
  }
}

# Permiso en Schema Registry (para schemas Avro)
resource "confluent_rbac_role_binding" "schema_registry_write" {
  principal   = "User:${var.principal_id}"
  role_name   = "DeveloperWrite"
  
  crn_pattern = "crn://confluent.cloud/schema-registry=${var.environment_id}"
  
  lifecycle {
    prevent_destroy = false
  }
}
```

**Nota**: El formato del CRN puede variar según tu configuración. Verifica la documentación de Confluent Cloud para el formato exacto en tu entorno.

## Resumen de Respuesta

**¿Los permisos RBAC se configuran en el JSON del conector?**
- ❌ **NO** - Los permisos RBAC se otorgan al Service Account **ANTES** del despliegue, no se configuran en el JSON

**¿El conector necesita un API Key adicional?**
- ❌ **NO** - No se requiere API Key adicional. El conector usa el Service Account configurado en `kafka.service.account.id`

**¿El conector necesita permisos RBAC en los topics?**
- ✅ **SÍ** - El Service Account necesita roles RBAC en:
  - **Sink Connectors**: `DeveloperRead` en topics de entrada + `DeveloperWrite` en DLQ
  - **Source Connectors**: `DeveloperWrite` en topics de salida + `DeveloperWrite` en DLQ
  - **Para ambos (si usan Avro)**: `DeveloperWrite` en Schema Registry

**¿Cómo se otorgan los permisos?**
- Mediante **RBAC (Role-Based Access Control)** usando el comando `confluent iam rbac role-binding create`
- Roles recomendados: 
  - `ResourceOwner` (permisos completos) - Para máxima flexibilidad
  - `DeveloperRead` (solo lectura) - Para topics de entrada en sinks
  - `DeveloperWrite` (solo escritura) - Para topics de salida y DLQ
- También se puede automatizar con Terraform usando el recurso `confluent_rbac_role_binding`

**¿Por qué RBAC y no ACLs?**
- En **Confluent Cloud dedicado**, RBAC es el método obligatorio de control de acceso
- RBAC proporciona mayor granularidad y mejor gestión de permisos a nivel de organización

## Checklist de Prerequisitos

Antes de desplegar un conector, verifica:

- [ ] Service Account creado y configurado en `kafka.service.account.id`
- [ ] Todos los topics creados (source/sink y DLQ)
- [ ] Schema Registry configurado y accesible
- [ ] Permisos RBAC otorgados al Service Account:
  - [ ] Para Sink: `DeveloperRead` en topics de entrada
  - [ ] Para Source: `DeveloperWrite` en topics de salida
  - [ ] Para ambos: `DeveloperWrite` en topic DLQ
  - [ ] **Para ambos: `DeveloperWrite` en Schema Registry** (si usan schemas Avro)
- [ ] JSON del conector configurado correctamente (sin permisos, solo configuración):
  - [ ] `input.data.format: "JSON_SR"` o `output.data.format: "JSON_SR"` configurado
  - [ ] `schema.context.name` configurado (generalmente `"default"`)
- [ ] Variables de Terraform configuradas (`principal_id`, `environment_id`, etc.)

