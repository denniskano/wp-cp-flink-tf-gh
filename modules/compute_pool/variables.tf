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

variable "cloud" {
  description = "Proveedor cloud para el compute pool"
  type        = string
  validation {
    condition     = contains(["AWS", "GCP", "AZURE"], var.cloud)
    error_message = "El proveedor cloud debe ser AWS, GCP o AZURE."
  }
}

variable "region" {
  description = "Región del compute pool"
  type        = string
}

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


