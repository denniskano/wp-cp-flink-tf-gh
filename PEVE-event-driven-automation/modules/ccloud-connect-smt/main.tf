locals {
  smt_doc = var.smt_file != "" && fileexists(var.smt_file) ? yamldecode(file(var.smt_file)) : tomap({})

  artifacts = {
    for a in try(local.smt_doc.artifacts, []) :
    a.name => {
      url            = a.url
      description    = try(a.description, "")
      content_format = upper(try(a.content_format, endswith(try(a.url, ""), ".zip") ? "ZIP" : "JAR"))
    }
    if try(a.name, "") != "" && try(a.url, "") != ""
  }
}

resource "terraform_data" "guards" {
  input = keys(local.artifacts)

  lifecycle {
    precondition {
      condition = alltrue([
        for name in keys(local.artifacts) : try(var.artifact_files[name], "") != ""
      ])
      error_message = "Falta artifact_files[name] (path local del JAR). El workflow tiene que bajar artifacts[].url de Artifactory antes del plan."
    }
    precondition {
      condition = alltrue([
        for name, path in var.artifact_files :
        !contains(keys(local.artifacts), name) || fileexists(path)
      ])
      error_message = "artifact_files apunta a un archivo que no existe en el runner."
    }
    precondition {
      condition     = contains(["AZURE", "AWS", "GCP"], var.cloud)
      error_message = "cloud tiene que ser AZURE, AWS o GCP."
    }
  }
}

# Custom SMT: environment + cloud. display_name único en ese alcance.
# ForceNew si cambia display_name / cloud / environment. Borrar el artifact
# deja Failed a los conectores que lo referencian.
resource "confluent_connect_artifact" "this" {
  for_each   = local.artifacts
  depends_on = [terraform_data.guards]

  display_name   = each.key
  cloud          = var.cloud
  content_format = each.value.content_format
  artifact_file  = var.artifact_files[each.key]
  description    = each.value.description

  environment {
    id = var.environment_id
  }
}
