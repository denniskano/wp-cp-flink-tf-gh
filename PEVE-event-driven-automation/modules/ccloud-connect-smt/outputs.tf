output "artifact_ids" {
  description = "name → ca-… para pegar en transforms.*.custom.smt.artifact.id"
  value       = { for name, a in confluent_connect_artifact.this : name => a.id }
}

output "artifacts" {
  value = {
    for name, a in confluent_connect_artifact.this :
    name => {
      id           = a.id
      display_name = a.display_name
      cloud        = a.cloud
    }
  }
}
