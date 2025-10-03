# 🏗️ Modelo Operativo - Gestión de Aplicaciones Flink

## 📋 Resumen Ejecutivo

Este documento define el modelo operativo para la gestión de aplicaciones Flink en Confluent Cloud, permitiendo que cada equipo de negocio (CODAPP) gestione de forma independiente sus recursos de infraestructura y statements SQL.

## 🎯 Objetivos

- **Autonomía**: Cada equipo gestiona sus propios recursos
- **Estandarización**: Nomenclatura y estructura consistente
- **Escalabilidad**: Soporte para múltiples aplicaciones y entornos
- **Trazabilidad**: Control de versiones y cambios
- **Seguridad**: Gestión granular de permisos

## 🏗️ Arquitectura del Modelo

### **Estructura de Directorios**
```
PEVE/
├── ccloud-flink-compute-pool/
│   ├── dev-vars.yaml          # Variables para desarrollo
│   ├── cert-vars.yaml         # Variables para certificación
│   └── prod-vars.yaml         # Variables para producción
└── ccloud-flink-statements/
    ├── ddl/
    │   ├── 01_[statement-name].yaml
    │   └── 02_[statement-name].yaml
    └── dml/
        ├── 01_[statement-name].yaml
        └── 02_[statement-name].yaml
```

## 📁 Estructura por Aplicación (CODAPP)

### **1. Compute Pool Configuration**

#### **Archivo: `{CODAPP}/ccloud-flink-compute-pool/dev-vars.yaml`**

```yaml
# =============================================================================
# COMPUTE POOL CONFIGURATION - DEVELOPMENT
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Development
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

# =============================================================================
# SECRETS HASHICORP VAULT
# =============================================================================
secrets_hv:
  service_account: SA_AZC_DES_{CODAPP}_POS_01    # Service Account ID
  api_key_terraform: AK_AZC_DES_{CODAPP}_TERRA_PAYMENT_01  # Cloud API Key
  api_key_flink: AK_AZC_DES_{CODAPP}_FLINK_PAYMENT_01      # Flink API Key

# =============================================================================
# COMPUTE POOLS CONFIGURATION
# =============================================================================
compute_pools:
  - cloud: "AZURE"                    # Cloud provider (AZURE/AWS/GCP)
    region: "westus2"                 # Azure region
    max_cfu: 5                        # Maximum Compute Flink Units
    pool_name: "CP_AZC_DES_{CODAPP}_01"  # Compute pool name
  - cloud: "AZURE"
    region: "westus2"
    max_cfu: 10
    pool_name: "CP_AZC_DES_{CODAPP}_02"
```

#### **Archivo: `{CODAPP}/ccloud-flink-compute-pool/cert-vars.yaml`**

```yaml
# =============================================================================
# COMPUTE POOL CONFIGURATION - CERTIFICATION
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Certification
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

secrets_hv:
  service_account: SA_AZC_CERT_{CODAPP}_POS_01
  api_key_terraform: AK_AZC_CERT_{CODAPP}_TERRA_PAYMENT_01
  api_key_flink: AK_AZC_CERT_{CODAPP}_FLINK_PAYMENT_01

compute_pools:
  - cloud: "AZURE"
    region: "westus2"
    max_cfu: 10
    pool_name: "CP_AZC_CERT_{CODAPP}_01"
  - cloud: "AZURE"
    region: "westus2"
    max_cfu: 20
    pool_name: "CP_AZC_CERT_{CODAPP}_02"
```

#### **Archivo: `{CODAPP}/ccloud-flink-compute-pool/prod-vars.yaml`**

```yaml
# =============================================================================
# COMPUTE POOL CONFIGURATION - PRODUCTION
# =============================================================================
# Aplicación: {CODAPP}
# Entorno: Production
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

secrets_hv:
  service_account: SA_AZC_PROD_{CODAPP}_POS_01
  api_key_terraform: AK_AZC_PROD_{CODAPP}_TERRA_PAYMENT_01
  api_key_flink: AK_AZC_PROD_{CODAPP}_FLINK_PAYMENT_01

compute_pools:
  - cloud: "AZURE"
    region: "westus2"
    max_cfu: 20
    pool_name: "CP_AZC_PROD_{CODAPP}_01"
  - cloud: "AZURE"
    region: "westus2"
    max_cfu: 50
    pool_name: "CP_AZC_PROD_{CODAPP}_02"
```

### **2. Flink Statements Configuration**

#### **Archivo: `{CODAPP}/ccloud-flink-statements/ddl/01_[statement-name].yaml`**

```yaml
# =============================================================================
# DDL STATEMENT - DATA DEFINITION LANGUAGE
# =============================================================================
# Aplicación: {CODAPP}
# Tipo: DDL (Data Definition Language)
# Entorno: All
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

# =============================================================================
# STATEMENT METADATA
# =============================================================================
statement-name: "create-demo-table"           # Nombre único del statement
statement-description: "Create demo table for {CODAPP} application"
flink-compute-pool: "CP_AZC_DES_{CODAPP}_01"  # Compute pool a utilizar
execution-order: 1                            # Orden de ejecución (1, 2, 3...)

# =============================================================================
# SQL STATEMENT
# =============================================================================
statement: |
  CREATE TABLE `${catalog_name}`.`${cluster_name}`.demo_table (
    id STRING,
    name STRING,
    created_at TIMESTAMP(3)
  ) WITH (
    'connector' = 'kafka',
    'topic' = 'demo-topic',
    'properties.bootstrap.servers' = 'localhost:9092'
  );
```

#### **Archivo: `{CODAPP}/ccloud-flink-statements/dml/01_[statement-name].yaml`**

```yaml
# =============================================================================
# DML STATEMENT - DATA MANIPULATION LANGUAGE
# =============================================================================
# Aplicación: {CODAPP}
# Tipo: DML (Data Manipulation Language)
# Entorno: All
# Última actualización: YYYY-MM-DD
# Responsable: [Nombre del equipo]

# =============================================================================
# STATEMENT METADATA
# =============================================================================
statement-name: "insert-demo-data"            # Nombre único del statement
statement-description: "Insert demo data for {CODAPP} application"
flink-compute-pool: "CP_AZC_DES_{CODAPP}_01"  # Compute pool a utilizar
execution-order: 1                            # Orden de ejecución (1, 2, 3...)

# =============================================================================
# SQL STATEMENT
# =============================================================================
statement: |
  INSERT INTO `${catalog_name}`.`${cluster_name}`.demo_table
  VALUES 
    ('1', 'Juan', CURRENT_TIMESTAMP),
    ('2', 'María', CURRENT_TIMESTAMP);
```

## 🔑 Prerrequisitos de Seguridad

### **1. Service Account Creation**

```bash
# Crear Service Account para la aplicación
confluent iam service-account create \
  --name "SA_AZC_DES_{CODAPP}_POS_01" \
  --description "Service Account para {CODAPP} - Development"
```

### **2. API Keys Creation**

#### **Cloud API Key (Terraform Provider)**
```bash
# Cloud API Key para Terraform
confluent api-key create \
  --resource cloud \
  --service-account sa-{service-account-id} \
  --description "Cloud API Key para {CODAPP} - Development"
```

#### **Flink API Key (Flink Statements)**
```bash
# Flink API Key para statements
confluent api-key create \
  --resource flink \
  --cloud azure \
  --region westus2 \
  --service-account sa-{service-account-id} \
  --description "Flink API Key para {CODAPP} - Development"
```

### **3. Role Assignments**

```bash
# FlinkAdmin - Para compute pools y statements
confluent iam rbac role-binding create \
  --principal User:sa-{service-account-id} \
  --role FlinkAdmin \
  --environment env-{environment-id}

# CloudClusterAdmin - Para acceso a clusters
confluent iam rbac role-binding create \
  --principal User:sa-{service-account-id} \
  --role CloudClusterAdmin \
  --environment env-{environment-id}

# Schema Registry - Para acceso a schemas
confluent iam rbac role-binding create \
  --principal User:sa-{service-account-id} \
  --role DeveloperManage \
  --schema-registry-subject "*" \
  --environment env-{environment-id}
```

## 📋 Nomenclatura y Estándares

### **1. Códigos de Aplicación (CODAPP)**
- **Formato**: 4 letras mayúsculas
- **Ejemplos**: `PEVE`, `PAYM`, `USER`, `AUTH`
- **Reglas**: Único por organización, descriptivo del negocio

### **2. Entornos**
- **Development**: `DES` (Desarrollo)
- **Certification**: `CERT` (Certificación)
- **Production**: `PROD` (Producción)

### **3. Recursos**
- **Service Account**: `SA_AZC_{ENV}_{CODAPP}_POS_01`
- **Cloud API Key**: `AK_AZC_{ENV}_{CODAPP}_TERRA_PAYMENT_01`
- **Flink API Key**: `AK_AZC_{ENV}_{CODAPP}_FLINK_PAYMENT_01`
- **Compute Pool**: `CP_AZC_{ENV}_{CODAPP}_01`

### **4. Archivos de Configuración**
- **Compute Pool**: `{env}-vars.yaml`
- **DDL Statements**: `{order}_{statement-name}.yaml`
- **DML Statements**: `{order}_{statement-name}.yaml`

## 🔧 Proceso Operativo

### **1. Onboarding de Nueva Aplicación**

#### **Paso 1: Crear Estructura de Directorios**
```bash
# Crear directorio de la aplicación
mkdir -p {CODAPP}/ccloud-flink-compute-pool
mkdir -p {CODAPP}/ccloud-flink-statements/ddl
mkdir -p {CODAPP}/ccloud-flink-statements/dml
```

#### **Paso 2: Configurar Compute Pools**
```bash
# Crear archivos de configuración por entorno
touch {CODAPP}/ccloud-flink-compute-pool/dev-vars.yaml
touch {CODAPP}/ccloud-flink-compute-pool/cert-vars.yaml
touch {CODAPP}/ccloud-flink-compute-pool/prod-vars.yaml
```

#### **Paso 3: Configurar Statements**
```bash
# Crear archivos de statements
touch {CODAPP}/ccloud-flink-statements/ddl/01_[statement-name].yaml
touch {CODAPP}/ccloud-flink-statements/dml/01_[statement-name].yaml
```

### **2. Gestión de Cambios**

#### **Versionado**
- **Git**: Control de versiones obligatorio
- **Branches**: `develop`, `cert`, `prod`
- **Tags**: Versionado semántico (v1.0.0)

#### **Aprobaciones**
- **Development**: Auto-aprobación
- **Certification**: Aprobación del equipo
- **Production**: Aprobación del arquitecto

### **3. Monitoreo y Alertas**

#### **Métricas Clave**
- **Compute Pool**: CFU utilization, status
- **Statements**: Execution status, latency
- **API Keys**: Usage, expiration

#### **Alertas**
- **Compute Pool**: Status changes, CFU limits
- **Statements**: Execution failures, timeouts
- **Security**: API key expiration, unauthorized access

## 📊 Matriz de Responsabilidades

| Componente | Equipo de Negocio | DevOps | Arquitectura |
|------------|-------------------|--------|--------------|
| **Compute Pools** | Configuración | Implementación | Aprobación |
| **Statements** | Desarrollo | Despliegue | Revisión |
| **API Keys** | Solicitud | Creación | Aprobación |
| **Monitoreo** | Consulta | Configuración | Diseño |

## 🔒 Consideraciones de Seguridad

### **1. Principio de Menor Privilegio**
- **Service Accounts**: Solo permisos necesarios
- **API Keys**: Scope limitado por aplicación
- **Roles**: Granular por recurso

### **2. Rotación de Credenciales**
- **API Keys**: Rotación cada 90 días
- **Service Accounts**: Revisión trimestral
- **Permisos**: Auditoría mensual

### **3. Auditoría y Compliance**
- **Logs**: Todas las operaciones registradas
- **Trazabilidad**: Cambios auditables
- **Compliance**: Cumplimiento de políticas

## 📈 Métricas y KPIs

### **1. Operacionales**
- **Tiempo de despliegue**: < 10 minutos
- **Disponibilidad**: 99.9%
- **Tiempo de recuperación**: < 30 minutos

### **2. Técnicos**
- **CFU Utilization**: 70-80%
- **Statement Latency**: < 100ms
- **Error Rate**: < 0.1%

### **3. Negocio**
- **Time to Market**: Reducción 50%
- **Cost Optimization**: 30% reducción
- **Developer Productivity**: 40% incremento

## 📚 Documentación y Recursos

### **1. Documentación Técnica**
- **API Reference**: Confluent Cloud APIs
- **Terraform Modules**: Documentación de módulos
- **GitHub Actions**: Workflows y triggers

### **2. Capacitación**
- **Onboarding**: Guías para nuevos equipos
- **Best Practices**: Patrones recomendados
- **Troubleshooting**: Guías de resolución

### **3. Soporte**
- **Slack Channel**: #flink-support
- **Documentación**: Wiki interno
- **Escalación**: Proceso definido

---

**Versión**: 1.0  
**Última actualización**: 2025-10-02  
**Responsable**: Arquitectura de Plataforma  
**Próxima revisión**: 2025-11-02