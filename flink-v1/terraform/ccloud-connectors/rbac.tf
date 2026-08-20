# =============================================================================
# RBAC — mismo schema YAML que flink-v2 (cluster.cc.rbac)
# Aplica topic, subject y transactional-id. Ignora compute-pool / FlinkDeveloper.
# =============================================================================

locals {
  # try() evita crash si el path no existe; terraform_data.guards bloquea el apply
  # para no interpretar "directorio ausente" como for_each vacío (destruiría RBAC).
  security_yaml_files = var.security_dir != "" ? try(fileset(var.security_dir, "*.yaml"), toset([])) : toset([])

  rbac_docs = [
    for f in local.security_yaml_files :
    yamldecode(file("${var.security_dir}/${f}"))
  ]

  rbac_entries = flatten([
    for doc in local.rbac_docs : [
      for binding in try(doc.cluster.cc.rbac, []) : [
        for res in try(binding.resources, []) : [
          for role in try(res.role, []) : {
            principal     = binding.principal
            resource_type = res.resource_type
            resource_name = res.resource_name
            pattern_type  = try(res.pattern_type, "LITERAL")
            role_name     = role.operation
          }
        ]
      ]
    ]
  ])

  rbac_supported = [
    for e in local.rbac_entries : e
    if contains(["topic", "subject", "transactional-id"], e.resource_type)
  ]

  rbac_map = {
    for e in local.rbac_supported :
    "${e.principal}:${e.resource_type}:${e.pattern_type}:${e.resource_name}:${e.role_name}" => e
  }

  rbac_principals = toset([for e in local.rbac_supported : e.principal])

  kafka_rbac_crn = data.confluent_kafka_cluster.cluster.rbac_crn
  sr_rbac_crn    = data.confluent_schema_registry_cluster.sr.resource_name
}

data "confluent_service_account" "rbac_sa" {
  for_each     = local.rbac_principals
  display_name = each.value
}

# Independiente de connects/*.yaml: borrar un conector NO quita estos bindings.
# Quitar o editar un YAML en security/ sí destruye solo las keys que desaparecen.
resource "confluent_role_binding" "connector_rbac" {
  for_each   = local.rbac_map
  depends_on = [terraform_data.guards]

  principal = "User:${data.confluent_service_account.rbac_sa[each.value.principal].id}"
  role_name = each.value.role_name

  crn_pattern = (
    each.value.resource_type == "topic" ? (
      "${local.kafka_rbac_crn}/kafka=${var.kafka_cluster_id}/topic=${each.value.resource_name}${each.value.pattern_type == "PREFIXED" ? "*" : ""}"
    ) : each.value.resource_type == "subject" ? (
      "${local.sr_rbac_crn}/subject=${each.value.resource_name}${each.value.pattern_type == "PREFIXED" ? "*" : ""}"
    ) : (
      "${local.kafka_rbac_crn}/kafka=${var.kafka_cluster_id}/transactional-id=${each.value.resource_name}${each.value.pattern_type == "PREFIXED" ? "*" : ""}"
    )
  )
}
