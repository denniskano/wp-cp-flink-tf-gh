# =============================================================================
# CONNECTORS MODULE
# Lee YAML en {CODAPP}/{desa|cert|prod}/{use-case}/connects/*.yaml
# =============================================================================

locals {
  # try(): fileset falla si el directorio no existe (p. ej. destroy tras borrar connects/).
  connector_yaml_files = try(fileset(var.connectors_dir, "*.yaml"), toset([]))

  connectors_data = {
    for f in local.connector_yaml_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.connectors_dir}/${f}"))
  }

  connector_sa_names = {
    for name, d in local.connectors_data :
    name => try(d["vault"]["service_account"], "")
  }

  unique_sa_names = toset([
    for sa in values(local.connector_sa_names) : sa if sa != ""
  ])

  connector_base_configs = {
    for name, d in local.connectors_data :
    name => try(d["config_nonsensitive"], {})
  }

  connector_topics = {
    for name, cfg in local.connector_base_configs :
    name => (
      try(cfg["topics"], "") != "" ?
      trimspace(split(",", tostring(cfg["topics"]))[0]) :
      try(tostring(cfg["kafka.topic"]), "")
    )
  }

  connector_dlq_configs = {
    for name, cfg in local.connector_base_configs :
    name => (
      local.connector_topics[name] != "" && try(cfg["errors.tolerance"], "") != "" ? {
        "errors.deadletterqueue.topic.name" = "${local.connector_topics[name]}-dlq"
      } : {}
    )
  }
}

data "confluent_service_account" "connector_sa" {
  for_each     = local.unique_sa_names
  display_name = each.value
}

data "confluent_kafka_cluster" "cluster" {
  id = var.kafka_cluster_id
  environment {
    id = var.environment_id
  }
}

data "confluent_schema_registry_cluster" "sr" {
  environment {
    id = var.environment_id
  }
}

locals {
  connector_sa_ids = {
    for name, sa_name in local.connector_sa_names :
    name => sa_name != "" ? data.confluent_service_account.connector_sa[sa_name].id : ""
  }

  connectors_processed = {
    for connector_name, d in local.connectors_data :
    connector_name => {
      name = try(
        d["name"],
        try(d["config_nonsensitive"]["name"], connector_name)
      )

      config_nonsensitive = merge(
        local.connector_base_configs[connector_name],
        {
          "name" = try(
            d["name"],
            try(d["config_nonsensitive"]["name"], connector_name)
          )
        },
        local.connector_sa_ids[connector_name] != "" ? {
          "kafka.service.account.id" = local.connector_sa_ids[connector_name]
        } : {},
        local.connector_dlq_configs[connector_name]
      )

      config_sensitive = {
        for k, v in merge(
          try(d["config_sensitive"], {}),
          try(var.connector_secrets[connector_name], {})
        ) : k => v if v != "" && v != null
      }

      status = lookup(
        var.connector_status_overrides,
        connector_name,
        upper(trimspace(try(d["status"], "RUNNING")))
      )
    }
  }
}

# check {} en Terraform 1.5 solo emite warning y NO bloquea apply.
# terraform_data + precondition sí falla el plan (incl. -target via depends_on).
resource "terraform_data" "guards" {
  input = keys(local.connectors_data)

  lifecycle {
    precondition {
      condition     = length(local.connectors_data) > 0 || var.allow_empty_connectors
      error_message = "connects/ no tiene archivos .yaml. Un apply vacío destruiría TODOS los conectores de este use-case (for_each). Si es intencional usa allow_empty_connectors=true o action destroy."
    }
    precondition {
      condition = alltrue([
        for k in keys(var.connector_status_overrides) : contains(keys(local.connectors_data), k)
      ])
      error_message = "connector_status_overrides referencia un conector que no está en connects/*.yaml. La key debe ser el nombre del archivo sin .yaml (ej. ccloud-azure-blob-storage-sink-connector-01)."
    }
    precondition {
      condition     = var.security_dir == "" || can(fileset(var.security_dir, "*.yaml"))
      error_message = "security_dir no existe o no es accesible. No se omite RBAC en silencio: un for_each vacío destruiría todos los role bindings. Crea security/ o pasa security_dir vacío."
    }
  }
}

# -----------------------------------------------------------------------------
# Full-Managed Kafka Connectors
# -----------------------------------------------------------------------------
# El topic DLQ debe existir de antemano. El SA necesita RBAC en topics/subjects
# (ver YAML en security/, mismo módulo).
#
# REGLA: no cambies 'name' ni el nombre del archivo YAML después del primer apply
# (ForceNew / cambia la key del for_each → recreate y pérdida de offsets).
# Borrar UN yaml destruye SOLO ese conector. Vaciar connects/ destruiría todos
# (bloqueado por terraform_data.guards).
resource "confluent_connector" "connectors" {
  for_each   = local.connectors_processed
  depends_on = [terraform_data.guards]

  environment {
    id = var.environment_id
  }

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  config_nonsensitive = each.value.config_nonsensitive
  config_sensitive    = each.value.config_sensitive
  status              = each.value.status

  lifecycle {
    precondition {
      condition     = can(each.value.config_nonsensitive["name"]) && each.value.config_nonsensitive["name"] != ""
      error_message = "El campo 'name' es obligatorio en el YAML del conector: ${each.key}. NO lo cambies después de la creación inicial."
    }
    precondition {
      condition     = contains(["RUNNING", "PAUSED"], each.value.status)
      error_message = "status del conector ${each.key} debe ser RUNNING o PAUSED (YAML o override)."
    }
  }
}
