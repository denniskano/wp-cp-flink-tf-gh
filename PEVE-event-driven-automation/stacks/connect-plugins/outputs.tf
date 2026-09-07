output "artifact_ids" {
  description = "name → ca-… para transforms.*.custom.smt.artifact.id"
  value       = module.smt.artifact_ids
}

output "artifacts" {
  value = module.smt.artifacts
}
