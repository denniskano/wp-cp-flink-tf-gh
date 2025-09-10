# =============================================================================
# INPUT VARIABLES
# =============================================================================

variable "environment_id" {
  description = "ID del Environment de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.environment_id))
    error_message = "El environment_id debe tener el formato 'env-xxxxx'."
  }
}

variable "compute_pool_id" {
  description = "ID del Flink compute pool destino"
  type        = string
  validation {
    condition     = can(regex("^lfcp-[a-z0-9]+$", var.compute_pool_id))
    error_message = "El compute_pool_id debe tener el formato 'lfcp-xxxxx'."
  }
}

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

variable "organization_id" {
  description = "ID de la organización de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.organization_id))
    error_message = "El organization_id debe ser un UUID válido."
  }
}

variable "principal_id" {
  description = "ID del principal (service account) de Confluent Cloud"
  type        = string
  validation {
    condition     = can(regex("^sa-[a-z0-9]+$", var.principal_id))
    error_message = "El principal_id debe tener el formato 'sa-xxxxx'."
  }
}

variable "api_key" {
  description = "API Key de Confluent Cloud para Flink"
  type        = string
  sensitive   = true
}

variable "api_secret" {
  description = "API Secret de Confluent Cloud para Flink"
  type        = string
  sensitive   = true
}
