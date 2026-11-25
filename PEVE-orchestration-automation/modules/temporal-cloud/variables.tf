variable "namespaces_dir" {
  description = "Directorio con namespaces/*.yaml"
  type        = string
}

variable "nexus_dir" {
  description = "Directorio con nexus/*.yaml (puede no existir)"
  type        = string
  default     = ""
}
