# 🏗️ Modelo Operativo - Gestión de Conectores Full-Managed Kafka

## 📋 Resumen Ejecutivo

Este documento define el modelo operativo para la gestión de conectores full-managed de Kafka en Confluent Cloud, permitiendo que cada equipo de negocio (CODAPP) gestione de forma independiente sus conectores con configuración por entorno.

## 🎯 Objetivos

- **Autonomía**: Cada equipo gestiona sus propios conectores
- **Estandarización**: Nomenclatura y estructura consistente
- **Escalabilidad**: Soporte para múltiples conectores y entornos
- **Trazabilidad**: Control de versiones y cambios
- **Seguridad**: Gestión granular de permisos y credenciales
- **Flexibilidad**: Soporte para cualquier conector full-managed disponible en Confluent Cloud

## 🏗️ Arquitectura del Modelo

### **Estructura de Directorios**

```
PEVE/
└── ccloud-connectors/
    ├── connector-01/
    │   ├── dev-connector-01.json    # Configuración base/non-sensitive para DES
    │   ├── cert-connector-01.json   # Configuración base/non-sensitive para CER
    │   ├── prod-connector-01.json   # Configuración base/non-sensitive para PRO
    │   ├── dev-vars.yaml            # Variables para desarrollo
    │   ├── cert-vars.yaml           # Variables para certificación
    │   └── prod-vars.yaml           # Variables para producción
    └── connector-02/
        ├── dev-connector-02.json
        ├── cert-connector-02.json
        ├── prod-connector-02.json
        ├── dev-vars.yaml
        ├── cert-vars.yaml
        └── prod-vars.yaml
```

## 📁 Estructura por Aplicación (CODAPP)

### **1. Configuración Base del Conector**

#### **Archivos JSON por entorno**

- `{CODAPP}/ccloud-connectors/{connector-name}/dev-{connector-name}.json`
- `{CODAPP}/ccloud-connectors/{connector-name}/cert-{connector-name}.json`
- `{CODAPP}/ccloud-connectors/{connector-name}/prod-{connector-name}.json`

Cada entorno tiene su propio JSON base (non-sensitive). Los valores adicionales/overrides por entorno se definen en `{env}-vars.yaml`.

```json
{
    "name": "sql-db-sink-connector-01",
    "config_nonsensitive": {
        "name": "sql-db-sink-connector-01",
        "schema.context.name": "default",
        "input.data.format": "JSON_SR",
        "delete.enabled": "false",
        "ignore.default.for.nullable": "false",
        "connector.class": "MicrosoftSqlserverSink",
        "kafka.auth.mode": "SERVICE_ACCOUNT",
        "ssl.mode": "prefer",
        "insert.mode": "INSERT",
        "table.types": "TABLE",
        "db.timezone": "UTC",
        "date.timezone": "DB_TIMEZONE",
        "auto.create": "true",
        "auto.evolve": "true",
        "quote.sql.identifiers": "ALWAYS",
        "batch.sizes": "3000",
        "max.poll.interval.ms": "300000",
        "max.poll.records": "500",
        "tasks.max": "1"
    }
}
```

**Notas importantes:**
- Cada archivo JSON de entorno debe contener `name` y `config_nonsensitive`
- Convención de nombre: `{prefix}-{connector-name}.json`, donde `{prefix}` es `dev`, `cert` o `prod`
- **NO incluir** valores específicos por entorno como:
  - `connection.host`
  - `connection.port`
  - `db.name`
  - `topics`
  - `kafka.service.account.id` (se inyecta automáticamente)
- Estos valores van en `{env}-vars.yaml` y sobrescriben el JSON del entorno

### **2. Variables por Entorno**

#### **Archivo: `{CODAPP}/ccloud-connectors/{connector-name}/dev-vars.yaml`**

```yaml
# =============================================================================
# CONNECTOR VARIABLES - DEVELOPMENT
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Development (DES)
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

# =============================================================================
# CONNECTOR CONFIGURATION (Non-Sensitive) - Environment Specific
# =============================================================================
config_nonsensitive:
  connection.host: "dev-database.example.com"
  connection.port: "1433"
  db.name: "dev-database-01"
  topics: "dev-topic-name"

# =============================================================================
# CONNECTOR CONFIGURATION (Sensitive) - Environment Specific
# =============================================================================
# Las credenciales se obtienen desde Vault o secrets
# Ejemplo de estructura (los valores reales vienen de secrets)
config_sensitive:
  connection.username: ""  # Se obtiene desde Vault/secrets
  connection.password: ""  # Se obtiene desde Vault/secrets

# =============================================================================
# CONNECTOR STATUS
# =============================================================================
# Estado del conector en este entorno
status: "RUNNING"
```

#### **Archivo: `{CODAPP}/ccloud-connectors/{connector-name}/cert-vars.yaml`**

```yaml
# =============================================================================
# CONNECTOR VARIABLES - CERTIFICATION
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Certification (CER)
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

config_nonsensitive:
  connection.host: "cert-database.example.com"
  connection.port: "1433"
  db.name: "cert-database-01"
  topics: "cert-topic-name"

config_sensitive:
  connection.username: ""  # Se obtiene desde Vault/secrets
  connection.password: ""  # Se obtiene desde Vault/secrets

status: "RUNNING"
```

#### **Archivo: `{CODAPP}/ccloud-connectors/{connector-name}/prod-vars.yaml`**

```yaml
# =============================================================================
# CONNECTOR VARIABLES - PRODUCTION
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Production (PRO)
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

config_nonsensitive:
  connection.host: "prod-database.example.com"
  connection.port: "1433"
  db.name: "prod-database-01"
  topics: "prod-topic-name"

config_sensitive:
  connection.username: ""  # Se obtiene desde Vault/secrets
  connection.password: ""  # Se obtiene desde Vault/secrets

status: "RUNNING"
```

## 🔐 Seguridad y Credenciales

### **Gestión de Credenciales Sensibles**

Las credenciales sensibles (passwords, API keys, etc.) deben gestionarse a través de:

1. **HashiCorp Vault**: Para almacenamiento seguro
2. **GitHub Secrets**: Para valores que se inyectan en el workflow
3. **Variables de entorno**: Para valores que se pasan al módulo de Terraform

**IMPORTANTE**: Nunca commitear credenciales en los archivos YAML. Usar placeholders vacíos (`""`) y obtener los valores desde Vault/secrets.

### **Ejemplo de Integración con Vault**

En el workflow de GitHub Actions, las credenciales se obtienen desde Vault:

```yaml
- name: Get Secrets for Connectors
  uses: hashicorp/vault-action@v2
  with:
    secrets: |
      peve/data/dev/peve/ccloud/{service-account}/{api-key} username | CONNECTOR_USERNAME ;
      peve/data/dev/peve/ccloud/{service-account}/{api-key} password | CONNECTOR_PASSWORD ;
```

Luego se pasan a Terraform como variables:

```yaml
TF_VAR_connector_username: ${{ env.CONNECTOR_USERNAME }}
TF_VAR_connector_password: ${{ env.CONNECTOR_PASSWORD }}
```

## 📋 Nomenclatura y Estándares

### **1. Códigos de Aplicación (CODAPP)**
- **Formato**: 4 letras mayúsculas
- **Ejemplos**: `PEVE`, `APSY`, `USER`, `AUTH`
- **Reglas**: Único por organización, descriptivo del negocio

### **2. Entornos**
- **Development**: `DES` (Desarrollo)
- **Certification**: `CER` (Certificación)
- **Production**: `PRO` (Producción)

### **3. Nomenclatura de Conectores**
- **Formato**: `{tipo}-{descripcion}-{secuencia}`
- **Ejemplos**: 
  - `ccloud-sql-db-sink-connector-01`
  - `ccloud-s3-sink-connector-01`
  - `ccloud-http-source-connector-01`

### **4. Archivos de Configuración**
- **Configuración base por entorno**:
  - `dev-{connector-name}.json`
  - `cert-{connector-name}.json`
  - `prod-{connector-name}.json`
- **Variables por entorno**: `{env}-vars.yaml` donde `{env}` es `dev`, `cert`, o `prod`

## 🔧 Proceso Operativo

### **1. Onboarding de Nuevo Conector**

#### **Paso 1: Crear Estructura de Directorios**
```bash
# Crear directorio del conector
mkdir -p {CODAPP}/ccloud-connectors/{connector-name}
```

#### **Paso 2: Crear Archivos de Configuración**
```bash
# Crear archivos de configuración
touch {CODAPP}/ccloud-connectors/{connector-name}/dev-{connector-name}.json
touch {CODAPP}/ccloud-connectors/{connector-name}/cert-{connector-name}.json
touch {CODAPP}/ccloud-connectors/{connector-name}/prod-{connector-name}.json
touch {CODAPP}/ccloud-connectors/{connector-name}/dev-vars.yaml
touch {CODAPP}/ccloud-connectors/{connector-name}/cert-vars.yaml
touch {CODAPP}/ccloud-connectors/{connector-name}/prod-vars.yaml
```

#### **Paso 3: Configurar Conector Base**
1. Editar `dev-{connector-name}.json`, `cert-{connector-name}.json` y `prod-{connector-name}.json` con la configuración base del entorno
2. Definir `name` del conector
3. Configurar `config_nonsensitive` con valores comunes (sin valores específicos por entorno)
4. **NO incluir** `config_sensitive` en el JSON (se define en vars)

#### **Paso 4: Configurar Variables por Entorno**
1. Editar `{env}-vars.yaml` para cada entorno
2. Definir valores específicos por entorno en `config_nonsensitive`
3. Definir estructura de `config_sensitive` (valores desde Vault)

### **2. Despliegue de Conectores**

#### **Usando GitHub Actions**

1. Ir a **Actions** → **Deploy Full-Managed Kafka Connectors**
2. Click en **Run workflow**
3. Seleccionar:
   - **CODAPP**: Código de aplicación (ej: `PEVE`)
   - **ENVIRONMENT**: Entorno (`DES`, `CER`, `PRO`)
   - **action**: Acción a realizar (`plan`, `apply`, `destroy`)
4. Click en **Run workflow**

#### **Usando Terraform Localmente**

```bash
cd terraform/ccloud-connectors

# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan \
  -var="environment_id=env-xxxxx" \
  -var="organization_id=xxxxx-xxxxx-xxxxx" \
  -var="kafka_cluster_id=lkc-xxxxx" \
  -var="connectors_dir=../../PEVE/ccloud-connectors" \
  -var="environment=DES" \
  -var="confluent_cloud_api_key=xxx" \
  -var="confluent_cloud_api_secret=xxx" \
  -var="principal_id=sa-xxxxx"

# Aplicar cambios
terraform apply
```

### **3. Gestión de Conectores Existentes**

#### **Actualizar Configuración**
1. Editar el archivo JSON del entorno (`dev-{connector-name}.json`, `cert-{connector-name}.json` o `prod-{connector-name}.json`) o `{env}-vars.yaml`
2. Hacer commit de los cambios
3. Ejecutar el workflow con `action: apply`

#### **Pausar/Reanudar Conector**
1. Editar `{env}-vars.yaml` y cambiar `status: "PAUSED"` o `status: "RUNNING"`
2. Ejecutar el workflow con `action: apply`

#### **Eliminar Conector**
1. Eliminar el directorio del conector: `rm -rf {CODAPP}/ccloud-connectors/{connector-name}`
2. Ejecutar el workflow con `action: apply` (Terraform detectará la eliminación)

## 🔄 Orden de Precedencia de Configuración

La configuración se combina en el siguiente orden (último sobrescribe):

1. **`{prefix}-{connector-name}.json`** → Configuración base del entorno (non-sensitive)
2. **`{env}-vars.yaml`** → Variables por entorno (sobrescribe JSON del entorno)
3. **Valores forzados** → `name` y `kafka.service.account.id` (siempre se aplican)

## 📊 Conectores Soportados

Este módulo soporta **cualquier conector full-managed** disponible en Confluent Cloud, incluyendo:

- **Sink Connectors**:
  - Microsoft SQL Server Sink
  - PostgreSQL Sink
  - MySQL Sink
  - MongoDB Sink
  - Elasticsearch Sink
  - S3 Sink
  - GCS Sink
  - Azure Blob Storage Sink
  - Y muchos más...

- **Source Connectors**:
  - HTTP Source
  - MySQL Source
  - PostgreSQL Source
  - MongoDB Source
  - Y muchos más...

Para ver la lista completa de conectores disponibles, consulta la [documentación de Confluent Cloud](https://docs.confluent.io/cloud/current/connectors/index.html).

## 🚨 Troubleshooting

### **Error: "Connector directory not found"**
- Verificar que el directorio `{CODAPP}/ccloud-connectors/{connector-name}` existe
- Verificar que contiene el JSON del entorno (ej: `dev-{connector-name}.json`)

### **Error: "Environment vars file not found"**
- Verificar que existe `{env}-vars.yaml` para el entorno seleccionado
- Verificar el mapeo: `DES` → `dev-vars.yaml`, `CER` → `cert-vars.yaml`, `PRO` → `prod-vars.yaml`

### **Error: "Invalid connector configuration"**
- Verificar que el archivo JSON tiene la estructura correcta
- Verificar que `name` está definido en el JSON
- Verificar que `config_nonsensitive` es un objeto en el JSON
- Verificar que el JSON es válido (usar un validador JSON)

### **Error: "Credentials not found"**
- Verificar que las credenciales están configuradas en Vault
- Verificar que el workflow tiene acceso a los secrets
- Verificar que las variables de entorno están correctamente configuradas

## 📚 Referencias

- [Confluent Cloud Connectors Documentation](https://docs.confluent.io/cloud/current/connectors/index.html)
- [Terraform Confluent Provider](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/connector)
- [Operational Model - Flink Statements](./OPERATIONAL_MODEL.md)

## 📝 Changelog

- **2024-01-XX**: Versión inicial del modelo operativo para conectores full-managed

