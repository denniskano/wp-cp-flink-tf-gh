# =============================================================================
# CONFLUENT CLOUD CONFIGURATION
# =============================================================================

variable "environment_id" {
  description = "ID del entorno de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.environment_id))
    error_message = "El environment_id debe tener el formato 'env-xxxxx'."
  }
}

variable "kafka_cluster_id" {
  description = "ID del cluster de Kafka"
  type        = string
  validation {
    condition     = can(regex("^lkc-[a-z0-9]+$", var.kafka_cluster_id))
    error_message = "El kafka_cluster_id debe tener el formato 'lkc-xxxxx'."
  }
}

variable "connector_config_path" {
  description = "Ruta al archivo de configuración del conector (JSON)"
  type        = string
  default     = "PEVE/ccloud-connectors/ccloud-sql-db-sink-connector-01/dev-ccloud-sql-db-sink-connector-01.json"
}

variable "topic_name" {
  description = "Nombre del topic de Kafka"
  type        = string
}

variable "sql_username" {
  description = "Usuario de la base de datos SQL"
  type        = string
  sensitive   = true
}

variable "sql_password" {
  description = "Contraseña de la base de datos SQL"
  type        = string
  sensitive   = true
}

variable "connector_status" {
  description = "Estado inicial del conector (RUNNING, PAUSED, etc.)"
  type        = string
  default     = "RUNNING"
  validation {
    condition     = contains(["RUNNING", "PAUSED", "FAILED"], var.connector_status)
    error_message = "El estado del conector debe ser RUNNING, PAUSED o FAILED."
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