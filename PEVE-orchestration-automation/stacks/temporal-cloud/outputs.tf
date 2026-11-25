output "namespace_ids" {
  value = module.temporal.namespace_ids
}

output "namespace_endpoints" {
  value = module.temporal.namespace_endpoints
}

output "namespace_mtls_endpoints" {
  value = module.temporal.namespace_mtls_endpoints
}

output "service_account_ids" {
  value = module.temporal.service_account_ids
}

output "apikey_tokens" {
  value     = module.temporal.apikey_tokens
  sensitive = true
}

output "nexus_ids" {
  value = module.temporal.nexus_ids
}

output "namespace_tags" {
  value = module.temporal.namespace_tags
}
