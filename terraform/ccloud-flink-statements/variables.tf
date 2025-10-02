# =============================================================================
# CONFLUENT CLOUD CONFIGURATION
# =============================================================================

variable "environment_id" {
  description = "ID del Environment en Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.environment_id))
    error_message = "El environment_id debe tener el formato 'env-xxxxx'."
  }
}

variable "organization_id" {
  description = "ID de la Organización en Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "El organization_id debe tener el formato UUID."
  }
}

variable "statements_dir" {
  description = "Directorio con archivos .yaml de DDL/DML"
  type        = string
}

# =============================================================================
# CONFLUENT CLOUD CREDENTIALS
# =============================================================================

variable "confluent_cloud_api_key" {
  description = "API Key de Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "API Secret de Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_flink_api_key" {
  description = "Flink API Key de Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_flink_api_secret" {
  description = "Flink API Secret de Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "principal_id" {
  description = "Service Account ID de Confluent Cloud"
  type        = string
  sensitive   = true
}

# =============================================================================
# FLINK STATEMENTS CONFIGURATION
# =============================================================================

variable "catalog_name" {
  description = "Nombre del catálogo para Flink statements"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  description = "Nombre del cluster para Flink statements"
  type        = string
  default     = "denniskano-clu"
}
