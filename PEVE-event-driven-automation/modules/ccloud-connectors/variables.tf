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
  description = "Directorio connects del caso de uso (YAML). Lo resuelve el workflow hacia ./externo."
  type        = string
}

variable "security_dir" {
  description = "Directorio security del caso de uso (YAML RBAC). Vacío = no aplica bindings."
  type        = string
  default     = ""
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

variable "connector_secrets" {
  description = "Secrets por conector (Vault o config_sensitive del YAML). Key = nombre del archivo sin .yaml."
  type        = map(map(string))
  default     = {}
  sensitive   = true
}

variable "connector_status_overrides" {
  description = "Forzar status (RUNNING|PAUSED) por conector. Vacío = status del YAML."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for s in values(var.connector_status_overrides) : contains(["RUNNING", "PAUSED"], s)])
    error_message = "connector_status_overrides solo admite RUNNING o PAUSED."
  }
}

variable "allow_empty_connectors" {
  description = "true permite connects/ sin YAML (destruiría todos los conectores del use-case)."
  type        = bool
  default     = false
}
