# Prerequisitos: Service Account y API Key

Este directorio contiene la configuración de Terraform para crear el service account y API key necesarios para el proyecto principal de Flink compute pool.

## ¿Por qué separado?

- El service account y API key son **prerequisitos** que debes crear antes del proyecto principal
- Una vez creados, las credenciales se almacenan en Vault
- El proyecto principal lee las credenciales desde Vault, no las crea

## Pasos para crear el service account

### 1. Configurar variables

```bash
cd prerequisites/service_account
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:
- `confluent_cloud_api_key`: Tu API key principal de Confluent Cloud
- `confluent_cloud_api_secret`: Tu API secret principal
- `confluent_environment_id`: ID del Environment donde crearás el compute pool
- Nombres del service account y API key

### 2. Ejecutar Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 3. Guardar credenciales en Vault

Después del `terraform apply`, verás outputs como:
```
service_account_id = "sa-xxxxx"
api_key = "AKIAXXXXX"
api_key_secret = "secret-xxxxx"
```

**Guarda estas credenciales en Vault:**

```bash
# Ejemplo usando vault CLI
vault kv put kv/confluent/cloud/creds \
  service_account_id="sa-xxxxx" \
  api_key="AKIAXXXXX" \
  api_secret="secret-xxxxx"
```

O usando la UI de Vault en la ruta `kv/confluent/cloud/creds` con las claves:
- `service_account_id`
- `api_key` 
- `api_secret`

### 4. Verificar permisos

El service account creado necesita permisos para:
- Crear y gestionar Flink compute pools
- Crear y gestionar Flink statements
- Acceso al Environment especificado

Puedes asignar estos permisos desde la UI de Confluent Cloud o usando Terraform adicional.

## Limpieza

Para eliminar el service account y API key:

```bash
terraform destroy
```

**Nota:** Esto eliminará permanentemente el service account y API key. Asegúrate de que no estén siendo usados por otros recursos.
