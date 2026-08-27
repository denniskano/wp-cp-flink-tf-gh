variable "environment_id" {
  description = "ID del Environment en Confluent Cloud"
  type        = string
}

variable "kafka_cluster_id" {
  description = "ID del cluster de Kafka"
  type        = string
}

variable "connectors_dir" {
  description = "Path a connects/ en el clone de resources (./externo/...)"
  type        = string
}

variable "security_dir" {
  description = "Path a security/ en el clone de resources. Vacío = sin RBAC."
  type        = string
  default     = ""
}

variable "environment" {
  description = "DES, CER o PRO"
  type        = string
  default     = "DES"
}

variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "connector_secrets" {
  type      = map(map(string))
  default   = {}
  sensitive = true
}

variable "connector_status_overrides" {
  type    = map(string)
  default = {}
}

variable "allow_empty_connectors" {
  type    = bool
  default = false
}
