# 🔑 Guía para Configurar API Keys y Service Account

## 📋 Resumen

Esta guía explica cómo configurar correctamente los API Keys y Service Account para el proyecto PEVE, considerando que actualmente los API Keys **NO** comparten el mismo Service Account.

## 🔍 Situación Actual

| API Key | Owner | Tipo | Service Account | Estado |
|---------|-------|------|-----------------|--------|
| `FVNKXPWM7H6YRP6G` | `u-qgjg1d` | **Cloud** | ❌ **Usuario personal** | ✅ Funciona |
| `O3GGBWSDX3KX624A` | `sa-k8jnkv6` | **Flink** | ✅ **Service Account** | ✅ Funciona |

## 🏗️ 1. Verificar/Crear Service Account

```bash
# Verificar si el Service Account existe
confluent iam service-account describe sa-k8jnkv6

# Si no existe, crearlo:
confluent iam service-account create \
  --name "SA_AZC_DES_PEVE_POS_01" \
  --description "Service Account para PEVE - Compute Pools y Flink Statements"
```

## 🎯 2. Asignar Roles al Service Account `sa-k8jnkv6`

### Para Compute Pools:
```bash
# EnvironmentAdmin - Para crear/gestionar compute pools
confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role EnvironmentAdmin \
  --environment env-XXXXX

# OrganizationAdmin - Para gestionar recursos a nivel organización
confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role OrganizationAdmin
```

### Para Flink Statements:
```bash
# FlinkAdmin - Para crear/gestionar Flink statements
confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role FlinkAdmin \
  --environment env-XXXXX

# FlinkDeveloper - Para desarrollar Flink applications
confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role FlinkDeveloper \
  --environment env-XXXXX

# EnvironmentAdmin - Para acceder a compute pools (ya asignado arriba)
```

## 🔑 3. Crear API Keys

### A. Cloud API Key para Terraform (REEMPLAZAR el actual):
```bash
# Crear Cloud API Key para el Service Account (reemplaza FVNKXPWM7H6YRP6G)
confluent api-key create \
  --resource cloud \
  --service-account sa-k8jnkv6 \
  --description "Cloud API Key para Service Account sa-k8jnkv6 - PEVE"

# Guarda el nuevo API Key y Secret
```

### B. Flink API Key (YA EXISTE - verificar):
```bash
# Verificar que el Flink API Key existe y es correcto
confluent api-key describe O3GGBWSDX3KX624A

# Si no existe, crearlo:
confluent api-key create \
  --resource flink \
  --cloud azure \
  --region westus2 \
  --service-account sa-k8jnkv6 \
  --description "Flink API Key para Service Account sa-k8jnkv6 - PEVE"
```

## 📋 4. Roles Necesarios por Funcionalidad

### 🏗️ Compute Pools:
| Rol | Propósito | Nivel | ¿Necesario? |
|-----|-----------|-------|-------------|
| `EnvironmentAdmin` | Crear/gestionar compute pools | Environment | ✅ **SÍ** |
| `OrganizationAdmin` | Acceso a recursos de organización | Organization | ✅ **SÍ** |

### 📝 Flink Statements:
| Rol | Propósito | Nivel | ¿Necesario? |
|-----|-----------|-------|-------------|
| `FlinkAdmin` | Crear/gestionar Flink statements | Environment | ✅ **SÍ** |
| `FlinkDeveloper` | Desarrollar Flink applications | Environment | ✅ **SÍ** |
| `EnvironmentAdmin` | Acceder a compute pools | Environment | ✅ **SÍ** |

## 🔧 5. Comandos de Verificación

### Verificar Service Account:
```bash
# Ver detalles del service account
confluent iam service-account describe sa-k8jnkv6

# Ver roles asignados
confluent iam rbac role-binding list \
  --principal User:sa-k8jnkv6 \
  --environment env-XXXXX
```

### Verificar API Keys:
```bash
# Listar API keys del service account
confluent api-key list \
  --service-account sa-k8jnkv6

# Ver detalles de cada API key
confluent api-key describe [CLOUD_API_KEY]
confluent api-key describe O3GGBWSDX3KX624A
```

## 🎯 6. Configuración Final Esperada

### ✅ Service Account: `sa-k8jnkv6`
- **EnvironmentAdmin** (para compute pools y acceso a environment)
- **OrganizationAdmin** (para acceso a nivel organización)
- **FlinkAdmin** (para gestionar Flink statements)
- **FlinkDeveloper** (para desarrollar Flink applications)

### 🔑 API Keys (AMBOS del mismo Service Account):
- **Cloud API Key**: Para Terraform provider (compute pools + statements)
- **Flink API Key**: Para Flink statements específicamente

## 🚀 7. Comandos Completos de Ejemplo

```bash
# 1. Verificar Service Account
confluent iam service-account describe sa-k8jnkv6

# 2. Asignar todos los roles necesarios
confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role EnvironmentAdmin \
  --environment env-XXXXX

confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role OrganizationAdmin

confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role FlinkAdmin \
  --environment env-XXXXX

confluent iam rbac role-binding create \
  --principal User:sa-k8jnkv6 \
  --role FlinkDeveloper \
  --environment env-XXXXX

# 3. Crear Cloud API Key para el Service Account
CLOUD_KEY=$(confluent api-key create \
  --resource cloud \
  --service-account sa-k8jnkv6 \
  --description "Cloud API Key para Service Account sa-k8jnkv6 - PEVE" \
  --output json | jq -r '.key')

CLOUD_SECRET=$(confluent api-key create \
  --resource cloud \
  --service-account sa-k8jnkv6 \
  --description "Cloud API Key para Service Account sa-k8jnkv6 - PEVE" \
  --output json | jq -r '.secret')

# 4. Verificar Flink API Key existente
confluent api-key describe O3GGBWSDX3KX624A

echo "Service Account ID: sa-k8jnkv6"
echo "Cloud API Key: $CLOUD_KEY"
echo "Cloud API Secret: $CLOUD_SECRET"
echo "Flink API Key: O3GGBWSDX3KX624A"
echo "Flink API Secret: [ya existe]"
```



## ✅ 10. Verificación Final

```bash
# Verificar que todo funciona
confluent environment list
confluent flink compute-pool list --environment env-XXXXX
confluent flink statement list --environment env-XXXXX
```

## 📝 Notas Importantes

1. **Situación Actual**: Los API Keys no comparten el mismo Service Account
2. **Funciona**: La configuración actual funciona pero no es la mejor práctica
3. **Recomendación**: Crear un Cloud API Key para el Service Account `sa-k8jnkv6`
4. **Roles**: Asegurar que el Service Account tenga todos los roles necesarios
5. **Vault**: Ajustar la estructura en Vault según la opción elegida

---

**Última actualización**: $(date)
**Versión**: 1.0
