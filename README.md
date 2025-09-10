# Confluent Cloud Flink Infrastructure

Este proyecto proporciona una solución completa de Infrastructure as Code (IaC) para aprovisionar recursos de Apache Flink en Confluent Cloud utilizando Terraform y GitHub Actions.

## 🏗️ Arquitectura

El proyecto está diseñado con una arquitectura modular que incluye:

- **Compute Pool**: Pool de cómputo de Flink en Confluent Cloud
- **Flink Statements**: DDL y DML statements para procesamiento de datos
- **Gestión de Secretos**: Integración con HashiCorp Vault para credenciales
- **CI/CD**: Automatización con GitHub Actions

## 📁 Estructura del Proyecto

```
├── main.tf                           # Configuración principal de Terraform
├── variables.tf                      # Variables de entrada
├── outputs.tf                        # Valores de salida
├── terraform.tfvars                  # Valores de variables locales
├── modules/
│   ├── compute_pool/                 # Módulo para Flink Compute Pool
│   │   ├── main.tf
│   │   └── variables.tf
│   └── terraform-ccloud-flink-statement/  # Módulo para Flink Statements
│       ├── main.tf
│       └── variables.tf
├── external/
│   ├── compute_pool-config.yaml     # Configuración del compute pool
│   └── statements/                   # Archivos SQL
│       ├── ddl.sql                   # Data Definition Language
│       └── dml.sql                   # Data Manipulation Language
├── prerequisites/
│   └── service_account/              # Módulo para crear service account
├── .github/
│   └── workflows/
│       └── terraform.yml             # Workflow de GitHub Actions
└── README.md
```

## 🚀 Prerrequisitos

### 1. Confluent Cloud
- Environment creado en Confluent Cloud
- Service Account con permisos apropiados
- API Keys (Cloud y Flink)

### 2. HashiCorp Vault
- Vault server ejecutándose
- KVv2 secrets engine habilitado
- Credenciales de Confluent Cloud almacenadas

### 3. Herramientas
- Terraform >= 1.5.0
- Confluent CLI
- Vault CLI

## ⚙️ Configuración

### 1. Configurar Vault

```bash
# Iniciar Vault (desarrollo)
vault server -dev

# Habilitar KVv2
vault secrets enable -path=kv kv-v2

# Almacenar credenciales
vault kv put kv/confluent/cloud/creds \
  cloud_api_key="your-cloud-api-key" \
  cloud_api_secret="your-cloud-api-secret" \
  flink_api_key="your-flink-api-key" \
  flink_api_secret="your-flink-api-secret" \
  service_account_id="sa-xxxxx"
```

### 2. Configurar Variables

Edita `terraform.tfvars` con tus valores:

```hcl
# Confluent Cloud
confluent_environment_id   = "env-xxxxx"
confluent_organization_id  = "your-org-id"
confluent_principal_id     = "sa-xxxxx"
confluent_cloud            = "AZURE"
confluent_region           = "westus2"

# Compute Pool
compute_pool_name          = "cp-flink-ejemplo"
compute_pool_config_path   = "external/compute_pool-config.yaml"

# Flink Statements
statements_dir             = "external/statements"
statement_name_prefix      = "stmt-demo-"
flink_rest_endpoint        = "https://flink.westus2.azure.confluent.cloud"

# Vault
vault_addr                 = "http://127.0.0.1:8200"
vault_kv_mount             = "kv"
vault_secret_path          = "confluent/cloud/creds"
```

## 🛠️ Uso

### Desarrollo Local

```bash
# Inicializar Terraform
terraform init

# Planificar cambios
terraform plan

# Aplicar cambios
terraform apply

# Destruir recursos
terraform destroy
```

### GitHub Actions CI/CD

#### Configuración Inicial

1. **Configurar Vault para GitHub Actions**:
```bash
# Editar variables en el script
export GITHUB_ORG="tu-organizacion"
export GITHUB_REPO="tu-repositorio"

# Ejecutar configuración
./scripts/setup-vault.sh
```

2. **Configurar credenciales en Vault**:
```bash
./scripts/setup-credentials.sh
```

3. **Configurar variables en GitHub**:
   - Ve a **Settings → Secrets and variables → Actions**
   - Agrega las variables de repositorio:
     - `VAULT_ADDR`: URL de tu servidor Vault
     - `VAULT_JWT_PATH`: `auth/jwt`
     - `VAULT_JWT_ROLE`: `github-actions`

#### Workflows Disponibles

- **Push a main/develop**: Validación automática de Terraform
- **Pull Request**: Plan de Terraform
- **Manual Dispatch**: Plan, Apply o Destroy

#### Despliegue Manual

1. Ve a **Actions** en tu repositorio
2. Selecciona **Confluent Cloud Flink Infrastructure**
3. Haz clic en **Run workflow**
4. Selecciona la acción (`plan`, `apply`, o `destroy`)
5. Haz clic en **Run workflow**

## 📊 Recursos Creados

### Compute Pool
- **Tipo**: Flink Compute Pool
- **Configuración**: Definida en `external/compute_pool-config.yaml`
- **Capacidad**: 5 CFU (configurable)

### Flink Statements
- **DDL**: Creación de tablas
- **DML**: Inserción y procesamiento de datos
- **Orden**: DDL se ejecuta antes que DML

## 🔐 Seguridad

- **Credenciales**: Almacenadas en HashiCorp Vault
- **API Keys**: Separadas para Cloud y Flink
- **Validación**: Variables con validación de formato
- **Sensibilidad**: Outputs marcados como no sensibles

## 📝 Flink SQL

### DDL (Data Definition Language)
```sql
CREATE TABLE `default`.`denniskano-clu`.demo_table (
  id STRING,
  name STRING,
  created_at TIMESTAMP(3)
) WITH (
  'connector' = 'confluent'
);
```

### DML (Data Manipulation Language)
```sql
INSERT INTO `default`.`denniskano-clu`.demo_table
VALUES 
  ('1', 'Juan', CURRENT_TIMESTAMP),
  ('2', 'María', CURRENT_TIMESTAMP),
  ('3', 'Pedro', CURRENT_TIMESTAMP);
```

## 🧪 Testing

```bash
# Validar configuración
terraform validate

# Formatear código
terraform fmt -recursive

# Verificar plan
terraform plan -detailed-exitcode
```

## 📚 Documentación Adicional

- [Confluent Cloud Documentation](https://docs.confluent.io/cloud/)
- [Terraform Confluent Provider](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🆘 Soporte

Para soporte y preguntas:
- Abre un issue en GitHub
- Consulta la documentación de Confluent Cloud
- Revisa los logs de Terraform para errores específicos

---

**Nota**: Este proyecto está diseñado para entornos de desarrollo y testing. Para producción, considera configuraciones adicionales de seguridad y monitoreo.