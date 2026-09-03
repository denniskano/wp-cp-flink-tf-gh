variable "cluster_id" {
  type      = string
  sensitive = true
  default = "-"
}

variable "mds_host" {
  description = "El endpoint de cluster"
  type      = string
  sensitive = true
  default = "-"
}

variable "mds_username" {
  description = "El api key del cluster kafka"
  type      = string
  sensitive = true
  default = "-"
}

variable "mds_password" {
  description = "El api secret del cluster kafka"
  type      = string
  sensitive = true
  default = "-"
}

variable "environment_id" {
  type      = string
  sensitive = true
  default = ""
}

variable "organization_id" {
  type      = string
  sensitive = true
  default = ""
}


//PARA SCHEMA REGISTRY
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

