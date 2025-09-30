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


variable "statements_dir" {
  description = "Directorio con archivos .yaml de DDL/DML"
  type        = string
  default     = "PEVE/ccloud-flink-statements"
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