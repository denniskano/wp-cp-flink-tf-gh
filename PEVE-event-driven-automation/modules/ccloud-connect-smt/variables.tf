variable "environment_id" {
  description = "Environment de Confluent Cloud (el artifact no es por cluster)."
  type        = string
}

variable "smt_file" {
  description = "Path a {CODAPP}/{env}/smt.yaml. Vacío = no hay SMT."
  type        = string
  default     = ""
}

variable "artifact_files" {
  description = "Mapa name → path local del JAR/ZIP (lo arma el workflow tras el curl a Artifactory)."
  type        = map(string)
  default     = {}
}

variable "cloud" {
  description = "CSP del artifact. El cluster PEVE es AZURE."
  type        = string
  default     = "AZURE"
}
