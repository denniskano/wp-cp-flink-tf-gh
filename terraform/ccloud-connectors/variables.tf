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

variable "kafka_cluster_id" {
  description = "ID del cluster de Kafka"
  type        = string
  validation {
    condition     = can(regex("^lkc-[a-z0-9]+$", var.kafka_cluster_id))
    error_message = "El kafka_cluster_id debe tener el formato 'lkc-xxxxx'."
  }
}

variable "connectors_dir" {
  description = "Directorio base con conectores (ej: ../../PEVE/ccloud-connectors)"
  type        = string
}

variable "environment" {
  description = "Environment para conectores (DES, CER, PRO)"
  type        = string
  default     = "DES"
  validation {
    condition     = contains(["DES", "CER", "PRO"], var.environment)
    error_message = "El environment debe ser DES, CER o PRO."
  }
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


