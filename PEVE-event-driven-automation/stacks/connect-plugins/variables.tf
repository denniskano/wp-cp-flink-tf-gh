variable "environment_id" {
  description = "ID del Environment en Confluent Cloud (el artifact no es por cluster)."
  type        = string
}

variable "smt_file" {
  description = "Path a {CODAPP}/{env}/smt.yaml en el clone de resources. Vacío = sin SMT."
  type        = string
  default     = ""
}

variable "artifact_files" {
  description = "Mapa name → path local del JAR/ZIP (el workflow lo arma tras el curl a Artifactory)."
  type        = map(string)
  default     = {}
}

variable "cloud" {
  description = "CSP del artifact. El cluster PEVE es AZURE."
  type        = string
  default     = "AZURE"
}

variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}
