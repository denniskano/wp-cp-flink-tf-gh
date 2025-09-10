terraform {
  required_version = ">= 1.5.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}

# Configuración del proveedor Confluent
# Las credenciales se pueden pasar via variables de entorno:
# TF_VAR_confluent_cloud_api_key
# TF_VAR_confluent_cloud_api_secret
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Service Account para Flink
resource "confluent_service_account" "flink_sa" {
  display_name = var.service_account_name
  description  = var.service_account_description
}

# API Key para el Service Account
resource "confluent_api_key" "flink_api_key" {
  display_name = var.api_key_name
  description  = var.api_key_description

  owner {
    id          = confluent_service_account.flink_sa.id
    api_version = confluent_service_account.flink_sa.api_version
    kind        = confluent_service_account.flink_sa.kind
  }

  # Para Flink compute pools, la API key se asocia al service account
  # El acceso al environment se maneja a través de permisos del service account
}

# Outputs para usar en el proyecto principal
output "service_account_id" {
  description = "ID del service account creado"
  value       = confluent_service_account.flink_sa.id
}

output "api_key_id" {
  description = "ID de la API key creada"
  value       = confluent_api_key.flink_api_key.id
}

output "api_key_secret" {
  description = "Secret de la API key (guárdalo en Vault)"
  value       = confluent_api_key.flink_api_key.secret
  sensitive   = true
}

output "api_key" {
  description = "API key (guárdala en Vault)"
  value       = confluent_api_key.flink_api_key.id
  sensitive   = true
}
