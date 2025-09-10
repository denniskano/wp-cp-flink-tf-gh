variable "confluent_cloud_api_key" {
  description = "API key de Confluent Cloud (tu usuario principal)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "API secret de Confluent Cloud (tu usuario principal)"
  type        = string
  sensitive   = true
}

variable "confluent_environment_id" {
  description = "ID del Environment en Confluent Cloud"
  type        = string
}

variable "service_account_name" {
  description = "Nombre del service account a crear"
  type        = string
}

variable "service_account_description" {
  description = "Descripción del service account"
  type        = string
  default     = "Service account para Flink compute pool"
}

variable "api_key_name" {
  description = "Nombre de la API key a crear"
  type        = string
}

variable "api_key_description" {
  description = "Descripción de la API key"
  type        = string
  default     = "API key para Flink compute pool"
}
