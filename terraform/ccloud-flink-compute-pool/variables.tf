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


variable "compute_pool_config_path" {
  description = "Ruta al archivo YAML con configuración del compute pool"
  type        = string
  default     = "PEVE/ccloud-flink-compute-pool/dev-vars.yaml"
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