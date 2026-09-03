variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "flink_private_rest_endpoint" {
  type    = string
  default = null
}

variable "sr_id" {
  description = "schema_registry_id"
  type        = string
  default     = ""
}

variable "sr_rest_endpoint" {
  description = "schema_registry_rest_endpoint"
  type        = string
  default     = ""
}

variable "sr_api_key" {
  description = "schema_registry_api_key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sr_api_secret" {
  description = "schema_registry_api_secret"
  type        = string
  default     = ""
  sensitive   = true
}
