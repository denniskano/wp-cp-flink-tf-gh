output "namespace_ids" {
  description = "Mapa name → id Temporal (name.accountid)"
  value       = { for k, n in temporalcloud_namespace.this : k => n.id }
}

output "namespace_endpoints" {
  description = "gRPC API key, o mTLS si el namespace no tiene API key"
  value = {
    for k, n in temporalcloud_namespace.this :
    k => coalesce(try(n.endpoints.grpc_address, ""), try(n.endpoints.mtls_grpc_address, ""), n.id)
  }
}

output "namespace_mtls_endpoints" {
  description = "gRPC mTLS (vacío si el namespace es solo API key)"
  value       = { for k, n in temporalcloud_namespace.this : k => try(n.endpoints.mtls_grpc_address, null) }
}

output "service_account_ids" {
  value = { for k, sa in temporalcloud_service_account.this : k => sa.id }
}

output "apikey_tokens" {
  description = "Tokens de API key (sensible). El GHA los sube a Vault; no imprimir."
  value       = { for k, ak in temporalcloud_apikey.this : k => ak.token }
  sensitive   = true
}

output "nexus_ids" {
  value = { for k, n in temporalcloud_nexus_endpoint.this : k => n.id }
}

output "namespace_tags" {
  description = "Tags aplicados (labels/tags del YAML)"
  value       = { for k, t in temporalcloud_namespace_tags.this : k => t.tags }
}
