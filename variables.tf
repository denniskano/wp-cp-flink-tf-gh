# =============================================================================
# CONFLUENT CLOUD CONFIGURATION
# =============================================================================

variable "confluent_environment_id" {
  description = "ID del Environment en Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.confluent_environment_id))
    error_message = "El environment_id debe tener el formato 'env-xxxxx'."
  }
}

variable "confluent_organization_id" {
  description = "ID de la organización de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.confluent_organization_id))
    error_message = "El organization_id debe ser un UUID válido."
  }
}

variable "confluent_principal_id" {
  description = "ID del principal (service account) de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^sa-[a-z0-9]+$", var.confluent_principal_id))
    error_message = "El principal_id debe tener el formato 'sa-xxxxx'."
  }
}

variable "confluent_cloud" {
  description = "Proveedor cloud para el compute pool"
  type        = string
  validation {
    condition     = contains(["AWS", "GCP", "AZURE"], var.confluent_cloud)
    error_message = "El proveedor cloud debe ser AWS, GCP o AZURE."
  }
}

variable "confluent_region" {
  description = "Región del compute pool"
  type        = string
}

# =============================================================================
# COMPUTE POOL CONFIGURATION
# =============================================================================

variable "compute_pool_name" {
  description = "Nombre del Flink compute pool"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.compute_pool_name))
    error_message = "El nombre del compute pool solo puede contener letras, números, guiones y guiones bajos."
  }
}

variable "compute_pool_config_path" {
  description = "Ruta al archivo YAML con configuración del compute pool"
  type        = string
}

# =============================================================================
# FLINK STATEMENTS CONFIGURATION
# =============================================================================

variable "statements_dir" {
  description = "Directorio con archivos .sql de DDL/DML"
  type        = string
}

variable "statement_name_prefix" {
  description = "Prefijo para los nombres de los statements"
  type        = string
  default     = "stmt-"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.statement_name_prefix))
    error_message = "El prefijo solo puede contener letras minúsculas, números y guiones."
  }
}

variable "flink_rest_endpoint" {
  description = "REST endpoint del Flink Compute Pool"
  type        = string
  validation {
    condition     = can(regex("^https://flink\\..+\\.confluent\\.cloud$", var.flink_rest_endpoint))
    error_message = "El endpoint debe ser una URL válida de Flink en Confluent Cloud."
  }
}

# =============================================================================
# VAULT CONFIGURATION
# =============================================================================

variable "vault_addr" {
  description = "URL del servidor de Vault"
  type        = string
  validation {
    condition     = can(regex("^https?://", var.vault_addr))
    error_message = "La URL de Vault debe comenzar con http:// o https://."
  }
}

variable "vault_kv_mount" {
  description = "Mount path del KVv2 en Vault"
  type        = string
  default     = "kv"
}

variable "vault_secret_path" {
  description = "Ruta del secreto KVv2 con credenciales de Confluent"
  type        = string
}


