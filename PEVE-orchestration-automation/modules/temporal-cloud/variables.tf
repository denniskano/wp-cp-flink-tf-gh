variable "namespaces_dir" {
  description = "Directorio con namespaces/*.yaml"
  type        = string
}

variable "nexus_dir" {
  description = "Directorio con nexus/*.yaml (puede no existir)"
  type        = string
  default     = ""
}

variable "mtls_ca_dir" {
  description = "Dir con <namespace>.pem bajados de Vault (fetch-temporal-ca-vault.sh). Vacío si ningún YAML usa accepted_client_ca_vault."
  type        = string
  default     = ""
}
