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

  # Extraer compute pools únicos de los archivos YAML
  all_compute_pools = distinct(concat(
    [for ddl in local.ddl_data : ddl["flink-compute-pool"]],
    [for dml in local.dml_data : dml["flink-compute-pool"]]
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
resource "confluent_flink_statement" "ddl_statements" {
  for_each = local.ddl_for_each

  statement_name = try(each.value["statement-name"], each.key)

  statement = replace(
    replace(
      each.value.statement,
      "$${catalog_name}", var.catalog_name
    ),
    "$${cluster_name}", var.cluster_name
  )

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
}

# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language) - Usando resource nativo
# -----------------------------------------------------------------------------
# Migración dml_statements[N] -> dml_statements["statement-name"]: mismo patrón que DDL arriba.
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "dml_statements" {
  for_each = local.dml_for_each

  statement_name = try(each.value["statement-name"], each.key)

  statement = replace(
    replace(
      each.value.statement,
      "$${catalog_name}", var.catalog_name
    ),
    "$${cluster_name}", var.cluster_name
  )

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

  depends_on = [confluent_flink_statement.ddl_statements]
}
