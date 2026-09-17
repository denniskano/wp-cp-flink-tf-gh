# =============================================================================
# FLINK STATEMENTS MODULE
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "confluent_flink_compute_pool" "by_name" {
  for_each = toset(local.all_compute_pools)

  display_name = each.value

  environment {
    id = var.environment_id
  }
}

data "confluent_flink_region" "by_region" {
  for_each = toset([
    for pool in data.confluent_flink_compute_pool.by_name : pool.region
  ])

  cloud  = data.confluent_flink_compute_pool.by_name[keys(data.confluent_flink_compute_pool.by_name)[0]].cloud
  region = each.value
}

data "confluent_service_account" "sa_princial" {
  display_name = var.sa_name
}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Confluent Flink API credentials (for statement management)
  confluent_cloud_api_key    = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret
  confluent_flink_api_key    = var.confluent_flink_api_key
  confluent_flink_api_secret = var.confluent_flink_api_secret
  sa_princial                = var.sa_name

  # Cargar archivos YAML de DDL y DML (orden = sort(fileset); listas para outputs / orden lógico)
  ddl_files    = sort(fileset("${var.statements_dir}/ddl", "*.yaml"))
  ddl_data_raw = [for f in local.ddl_files : yamldecode(file("${var.statements_dir}/ddl/${f}"))]
  ddl_data = [
    for ddl in local.ddl_data_raw : merge(
      ddl,
      {
        "flink-compute-pool" = replace(ddl["flink-compute-pool"], "$${environment}", var.environment)
      }
    )
  ]

  dml_files    = sort(fileset("${var.statements_dir}/dml", "*.yaml"))
  dml_data_raw = [for f in local.dml_files : yamldecode(file("${var.statements_dir}/dml/${f}"))]
  dml_data = [
    for dml in local.dml_data_raw : merge(
      dml,
      {
        "flink-compute-pool" = replace(dml["flink-compute-pool"], "$${environment}", var.environment)
      }
    )
  ]

  # for_each: clave estable = statement-name (único por YAML). Si faltara, nombre del archivo sin .yaml
  ddl_for_each = {
    for idx in range(length(local.ddl_files)) :
    coalesce(try(local.ddl_data[idx]["statement-name"], null), trimsuffix(local.ddl_files[idx], ".yaml")) => local.ddl_data[idx]
  }
  dml_for_each = {
    for idx in range(length(local.dml_files)) :
    coalesce(try(local.dml_data[idx]["statement-name"], null), trimsuffix(local.dml_files[idx], ".yaml")) => local.dml_data[idx]
  }

  # apply: managed (default) | ignore | once
  # ignore = fuera del for_each. once = se crea una vez; el marcador queda en el state.
  apply_modes = toset(["managed", "ignore", "once"])

  ddl_apply = {
    for k, v in local.ddl_for_each :
    k => coalesce(try(trimspace(lower(tostring(v["apply"]))), null), "managed")
  }
  dml_apply = {
    for k, v in local.dml_for_each :
    k => coalesce(try(trimspace(lower(tostring(v["apply"]))), null), "managed")
  }

  apply_flag_errors = concat(
    [for k, m in local.ddl_apply : "ddl/${k}=${m}" if !contains(local.apply_modes, m)],
    [for k, m in local.dml_apply : "dml/${k}=${m}" if !contains(local.apply_modes, m)]
  )

  ddl_managed = { for k, v in local.ddl_for_each : k => v if local.ddl_apply[k] == "managed" }
  dml_managed = { for k, v in local.dml_for_each : k => v if local.dml_apply[k] == "managed" }
  ddl_once    = { for k, v in local.ddl_for_each : k => v if local.ddl_apply[k] == "once" }
  dml_once    = { for k, v in local.dml_for_each : k => v if local.dml_apply[k] == "once" }
  ddl_ignored = { for k, v in local.ddl_for_each : k => v if local.ddl_apply[k] == "ignore" }
  dml_ignored = { for k, v in local.dml_for_each : k => v if local.dml_apply[k] == "ignore" }

  ddl_sql = {
    for k, v in local.ddl_for_each :
    k => replace(replace(v.statement, "$${catalog_name}", var.catalog_name), "$${cluster_name}", var.cluster_name)
  }
  dml_sql = {
    for k, v in local.dml_for_each :
    k => replace(replace(v.statement, "$${catalog_name}", var.catalog_name), "$${cluster_name}", var.cluster_name)
  }

  ddl_properties = {
    for k, v in local.ddl_for_each :
    k => { for pk, pv in try(v["properties"], {}) : tostring(pk) => tostring(pv) }
  }
  dml_properties = {
    for k, v in local.dml_for_each :
    k => { for pk, pv in try(v["properties"], {}) : tostring(pk) => tostring(pv) }
  }

  # Pools de lo que Terraform va a tocar (managed + once). ignore no pide data source.
  all_compute_pools = distinct(concat(
    [for k, v in local.ddl_for_each : v["flink-compute-pool"] if local.ddl_apply[k] != "ignore"],
    [for k, v in local.dml_for_each : v["flink-compute-pool"] if local.dml_apply[k] != "ignore"]
  ))

  # Mapeo de compute pools (necesario para asociar statements con compute pools)
  compute_pools_map = {
    for pool_name in local.all_compute_pools :
    pool_name => {
      id                    = data.confluent_flink_compute_pool.by_name[pool_name].id
      rest_endpoint         = data.confluent_flink_region.by_region[data.confluent_flink_compute_pool.by_name[pool_name].region].rest_endpoint
      private_rest_endpoint = var.flink_private_rest_endpoint
    }
  }
}

# =============================================================================
# RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# DDL Statements (Data Definition Language) - Usando resource nativo
# -----------------------------------------------------------------------------
# Migración count -> for_each: si el state aún tiene ddl_statements[N], antes de apply
# renombra cada instancia al nuevo address (clave = statement-name del YAML, ver local.ddl_for_each):
#   terraform state mv 'confluent_flink_statement.ddl_statements[N]' 'confluent_flink_statement.ddl_statements["NOMBRE_STATEMENT"]'
# No añadimos bloques moved fijos aquí: el índice [N] significa cosas distintas por CODAPP/statements_dir.
# -----------------------------------------------------------------------------
resource "terraform_data" "apply_flag_guard" {
  input = "apply-flag-guard"

  lifecycle {
    precondition {
      condition     = length(local.apply_flag_errors) == 0
      error_message = "apply debe ser managed, ignore o once (o omitirse). Inválido: ${join(", ", local.apply_flag_errors)}"
    }
  }
}

resource "confluent_flink_statement" "ddl_statements" {
  for_each = local.ddl_managed

  statement_name = try(each.value["statement-name"], each.key)

  statement = local.ddl_sql[each.key]

  properties = local.ddl_properties[each.key]

  stopped = try(each.value["stopped"], false)

  organization {
    id = var.organization_id
  }

  environment {
    id = var.environment_id
  }

  compute_pool {
    id = local.compute_pools_map[each.value["flink-compute-pool"]].id
  }

  principal {
    id = data.confluent_service_account.sa_princial.id
  }

  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }

  rest_endpoint = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint

  depends_on = [terraform_data.apply_flag_guard]
}

# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language) - Usando resource nativo
# -----------------------------------------------------------------------------
# Migración dml_statements[N] -> dml_statements["statement-name"]: mismo patrón que DDL arriba.
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "dml_statements" {
  for_each = local.dml_managed

  statement_name = try(each.value["statement-name"], each.key)

  statement = local.dml_sql[each.key]

  properties = local.dml_properties[each.key]

  stopped = try(each.value["stopped"], false)

  organization {
    id = var.organization_id
  }

  environment {
    id = var.environment_id
  }

  compute_pool {
    id = local.compute_pools_map[each.value["flink-compute-pool"]].id
  }

  principal {
    id = data.confluent_service_account.sa_princial.id
  }

  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }

  rest_endpoint = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint

  depends_on = [
    confluent_flink_statement.ddl_statements,
    terraform_data.ddl_once,
  ]
}

# -----------------------------------------------------------------------------
# apply: once — el statement se crea una vez (API). El marcador vive en el state.
# CCloud puede borrar el job a los 30 días; Terraform no lo vuelve a crear.
# ignore_changes: cambiar el SQL no re-dispara. Para repetir, cambia statement-name.
# -----------------------------------------------------------------------------
resource "terraform_data" "ddl_once" {
  for_each = local.ddl_once

  input = {
    name       = try(each.value["statement-name"], each.key)
    statement  = local.ddl_sql[each.key]
    pool_id    = local.compute_pools_map[each.value["flink-compute-pool"]].id
    rest       = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint
    org_id     = var.organization_id
    env_id     = var.environment_id
    principal  = data.confluent_service_account.sa_princial.id
    stopped    = tostring(try(each.value["stopped"], false))
    properties = jsonencode(local.ddl_properties[each.key])
  }

  provisioner "local-exec" {
    when    = create
    command = "bash ${path.module}/scripts/apply-once.sh"
    environment = {
      ONCE_ACTION                = "create"
      ONCE_NAME                  = self.input.name
      ONCE_SQL                   = self.input.statement
      ONCE_POOL_ID               = self.input.pool_id
      ONCE_REST_ENDPOINT         = self.input.rest
      ONCE_ORG_ID                = self.input.org_id
      ONCE_ENV_ID                = self.input.env_id
      ONCE_PRINCIPAL             = self.input.principal
      ONCE_STOPPED               = self.input.stopped
      ONCE_PROPERTIES            = self.input.properties
      CONFLUENT_FLINK_API_KEY    = var.confluent_flink_api_key
      CONFLUENT_FLINK_API_SECRET = var.confluent_flink_api_secret
    }
  }

  # Destroy-time provisioner no puede usar var.* (solo self). No borramos el
  # statement en CCloud al quitar el marcador: un DDL COMPLETED caduca solo.

  lifecycle {
    ignore_changes = [input]
    precondition {
      condition     = length(local.apply_flag_errors) == 0
      error_message = "apply debe ser managed, ignore o once (o omitirse). Inválido: ${join(", ", local.apply_flag_errors)}"
    }
  }

  depends_on = [terraform_data.apply_flag_guard]
}

resource "terraform_data" "dml_once" {
  for_each = local.dml_once

  input = {
    name       = try(each.value["statement-name"], each.key)
    statement  = local.dml_sql[each.key]
    pool_id    = local.compute_pools_map[each.value["flink-compute-pool"]].id
    rest       = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint
    org_id     = var.organization_id
    env_id     = var.environment_id
    principal  = data.confluent_service_account.sa_princial.id
    stopped    = tostring(try(each.value["stopped"], false))
    properties = jsonencode(local.dml_properties[each.key])
  }

  provisioner "local-exec" {
    when    = create
    command = "bash ${path.module}/scripts/apply-once.sh"
    environment = {
      ONCE_ACTION                = "create"
      ONCE_NAME                  = self.input.name
      ONCE_SQL                   = self.input.statement
      ONCE_POOL_ID               = self.input.pool_id
      ONCE_REST_ENDPOINT         = self.input.rest
      ONCE_ORG_ID                = self.input.org_id
      ONCE_ENV_ID                = self.input.env_id
      ONCE_PRINCIPAL             = self.input.principal
      ONCE_STOPPED               = self.input.stopped
      ONCE_PROPERTIES            = self.input.properties
      CONFLUENT_FLINK_API_KEY    = var.confluent_flink_api_key
      CONFLUENT_FLINK_API_SECRET = var.confluent_flink_api_secret
    }
  }

  lifecycle {
    ignore_changes = [input]
  }

  depends_on = [
    confluent_flink_statement.ddl_statements,
    terraform_data.ddl_once,
    terraform_data.apply_flag_guard,
  ]
}
