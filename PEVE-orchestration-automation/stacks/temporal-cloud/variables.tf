variable "temporal_cloud_api_key" {
  description = "API key de cuenta Temporal Cloud (Vault). Privilegio Namespace management."
  type        = string
  sensitive   = true
}

variable "namespaces_dir" {
  description = "Ruta a {CODAPP}/{env}/namespaces"
  type        = string
}

variable "nexus_dir" {
  description = "Ruta a {CODAPP}/{env}/nexus"
  type        = string
  default     = ""
}
