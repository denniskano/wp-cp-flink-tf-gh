locals {
  namespace_files = try(fileset(var.namespaces_dir, "*.yaml"), toset([]))

  namespaces = {
    for f in local.namespace_files :
    yamldecode(file("${var.namespaces_dir}/${f}")).name => yamldecode(file("${var.namespaces_dir}/${f}"))
  }

  connectivity_rules = {
    for item in flatten([
      for ns_name, ns in local.namespaces : [
        for c in try(ns.connectivity, []) : {
          name                 = c.name
          connectivity_type    = c.type
          region               = try(c.region, null)
          connection_id        = try(c.connection_id, null)
          azure_pe_resource_id = try(c.azure_pe_resource_id, null)
          gcp_project_id       = try(c.gcp_project_id, null)
          enable_stable_ips    = try(c.enable_stable_ips, null)
        }
      ]
    ]) : item.name => item
  }

  search_attributes = {
    for item in flatten([
      for ns_name, ns in local.namespaces : [
        for sa in try(ns.search_attributes, []) : {
          key       = "${ns.name}/${sa.name}"
          namespace = ns.name
          name      = sa.name
          type      = sa.type
        }
      ]
    ]) : item.key => item
  }

  service_accounts = {
    for item in flatten([
      for ns_name, ns in local.namespaces : [
        for sa in try(ns.service_accounts, []) : {
          name             = sa.name
          namespace        = ns.name
          permission       = try(sa.permission, "write")
          account_access   = try(sa.account_access, "developer")
          extra_namespaces = try(sa.extra_namespaces, [])
        }
      ]
    ]) : item.name => item
  }

  api_keys = {
    for item in flatten([
      for ns_name, ns in local.namespaces : [
        for sa in try(ns.service_accounts, []) : [
          for k in try(sa.api_keys, []) : {
            key          = k.display_name
            display_name = k.display_name
            sa_name      = sa.name
            expiry_time  = k.expiry_time
            disabled     = try(k.disabled, false)
          }
        ]
      ]
    ]) : item.key => item
  }

  users = {
    for item in flatten([
      for ns_name, ns in local.namespaces : [
        for u in try(ns.users, []) : {
          email      = u.email
          namespace  = ns.name
          permission = try(u.permission, "write")
        }
      ]
    ]) : item.email => item
  }

  nexus_dir_effective = var.nexus_dir != "" ? var.nexus_dir : "${dirname(var.namespaces_dir)}/nexus"
  nexus_files         = try(fileset(local.nexus_dir_effective, "*.yaml"), toset([]))
  nexus = {
    for f in local.nexus_files :
    yamldecode(file("${local.nexus_dir_effective}/${f}")).name => yamldecode(file("${local.nexus_dir_effective}/${f}"))
  }

  # YAML `labels` (alias `tags`). Si ambos existen, `tags` pisa claves repetidas.
  namespace_tags = {
    for ns_name, ns in local.namespaces :
    ns_name => {
      for k, v in merge(try(ns.labels, {}), try(ns.tags, {})) : k => tostring(v)
    }
    if length(merge(try(ns.labels, {}), try(ns.tags, {}))) > 0
  }

  namespaces_need_vault_ca = {
    for ns_name, ns in local.namespaces :
    ns_name => ns
    if try(ns.accepted_client_ca_vault.path, "") != ""
  }

  # 1) PEM bajado de Vault a mtls_ca_dir/<name>.pem  2) inline  3) archivo en git (solo pruebas)
  fetched_ca = {
    for ns_name, ns in local.namespaces :
    ns_name => (
      try(ns.accepted_client_ca_vault.path, "") != "" && var.mtls_ca_dir != ""
      ? file("${var.mtls_ca_dir}/${ns_name}.pem")
      : ""
    )
  }

  namespace_client_ca = {
    for ns_name, ns in local.namespaces :
    ns_name => (
      local.fetched_ca[ns_name] != ""
      ? (
        startswith(trimspace(local.fetched_ca[ns_name]), "-----BEGIN")
        ? base64encode(local.fetched_ca[ns_name])
        : trimspace(local.fetched_ca[ns_name])
      )
      : (
        try(trimspace(ns.accepted_client_ca), "") != ""
        ? (
          startswith(trimspace(ns.accepted_client_ca), "-----BEGIN")
          ? base64encode(ns.accepted_client_ca)
          : trimspace(ns.accepted_client_ca)
        )
        : (
          try(ns.accepted_client_ca_file, "") != ""
          ? base64encode(file("${var.namespaces_dir}/${ns.accepted_client_ca_file}"))
          : null
        )
      )
    )
  }
}

check "mtls_ca_from_vault" {
  assert {
    condition     = length(local.namespaces_need_vault_ca) == 0 || var.mtls_ca_dir != ""
    error_message = "Hay accepted_client_ca_vault en el YAML: corré scripts/ci/fetch-temporal-ca-vault.sh y pasá TF_VAR_mtls_ca_dir."
  }
}

resource "temporalcloud_connectivity_rule" "this" {
  for_each = local.connectivity_rules

  connectivity_type    = each.value.connectivity_type
  region               = each.value.region
  connection_id        = each.value.connection_id
  azure_pe_resource_id = each.value.azure_pe_resource_id
  gcp_project_id       = each.value.gcp_project_id
  enable_stable_ips    = each.value.enable_stable_ips
}

resource "temporalcloud_namespace" "this" {
  for_each = local.namespaces

  name               = each.value.name
  regions            = each.value.regions
  api_key_auth       = try(each.value.api_key_auth, true)
  accepted_client_ca = local.namespace_client_ca[each.key]
  retention_days     = try(each.value.retention_days, 14)

  connectivity_rule_ids = [
    for c in try(each.value.connectivity, []) : temporalcloud_connectivity_rule.this[c.name].id
  ]

  dynamic "certificate_filters" {
    for_each = try(each.value.certificate_filters, [])
    content {
      common_name              = try(certificate_filters.value.common_name, null)
      organization             = try(certificate_filters.value.organization, null)
      organizational_unit      = try(certificate_filters.value.organizational_unit, null)
      subject_alternative_name = try(certificate_filters.value.subject_alternative_name, null)
    }
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "temporalcloud_namespace_tags" "this" {
  for_each = local.namespace_tags

  namespace_id = temporalcloud_namespace.this[each.key].id
  tags         = each.value
}

resource "temporalcloud_namespace_search_attribute" "this" {
  for_each = local.search_attributes

  namespace_id = temporalcloud_namespace.this[each.value.namespace].id
  name         = each.value.name
  type         = each.value.type
}

resource "temporalcloud_service_account" "this" {
  for_each = local.service_accounts

  name           = each.value.name
  account_access = each.value.account_access

  namespace_accesses = concat(
    [
      {
        namespace_id = temporalcloud_namespace.this[each.value.namespace].id
        permission   = each.value.permission
      }
    ],
    [
      for extra in each.value.extra_namespaces : {
        namespace_id = temporalcloud_namespace.this[extra.name].id
        permission   = try(extra.permission, "read")
      }
    ]
  )
}

resource "temporalcloud_apikey" "this" {
  for_each = local.api_keys

  display_name = each.value.display_name
  owner_type   = "service-account"
  owner_id     = temporalcloud_service_account.this[each.value.sa_name].id
  expiry_time  = each.value.expiry_time
  disabled     = each.value.disabled
}

resource "temporalcloud_user" "this" {
  for_each = local.users

  email          = each.value.email
  account_access = "developer"
  namespace_accesses = [
    {
      namespace_id = temporalcloud_namespace.this[each.value.namespace].id
      permission   = each.value.permission
    }
  ]
}

resource "temporalcloud_nexus_endpoint" "this" {
  for_each = local.nexus

  name        = each.value.name
  description = try(each.value.description, null)

  worker_target = {
    namespace_id = temporalcloud_namespace.this[each.value.target_namespace].id
    task_queue   = each.value.task_queue
  }

  allowed_caller_namespaces = [
    for caller in each.value.allowed_callers : temporalcloud_namespace.this[caller].id
  ]
}
