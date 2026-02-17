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

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Confluent Flink API credentials (for statement management)
  confluent_cloud_api_key    = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret
  confluent_flink_api_key    = var.confluent_flink_api_key
  confluent_flink_api_secret = var.confluent_flink_api_secret
  
  
  # Cargar archivos YAML de DDL y DML (ordenados alfabéticamente para asegurar orden de ejecución)
  ddl_files = sort(fileset("${var.statements_dir}/ddl", "*.yaml"))
  
  # Crear mapa DDL usando nombre de archivo como clave (para for_each)
  # Esto permite que Terraform identifique recursos por archivo, no por statement-name
  ddl_map = {
    for f in local.ddl_files : f => merge(
      yamldecode(file("${var.statements_dir}/ddl/${f}")),
      {
        "flink-compute-pool" = replace(
          yamldecode(file("${var.statements_dir}/ddl/${f}"))["flink-compute-pool"],
          "$${environment}",
          var.environment
        )
      }
    )
  }
  
  dml_files = sort(fileset("${var.statements_dir}/dml", "*.yaml"))
  
  # Crear mapa DML usando nombre de archivo como clave (para for_each)
  dml_map = {
    for f in local.dml_files : f => merge(
      yamldecode(file("${var.statements_dir}/dml/${f}")),
      {
        "flink-compute-pool" = replace(
          yamldecode(file("${var.statements_dir}/dml/${f}"))["flink-compute-pool"],
          "$${environment}",
          var.environment
        )
      }
    )
  }
  
  # Extraer compute pools únicos de los archivos YAML (después del reemplazo)
  all_compute_pools = distinct(concat(
    [for ddl in local.ddl_map : ddl["flink-compute-pool"]],
    [for dml in local.dml_map : dml["flink-compute-pool"]]
  ))
  
  # Mapeo de compute pools (necesario para asociar statements con compute pools)
  compute_pools_map = {
    for pool_name in local.all_compute_pools :
    pool_name => {
      id = data.confluent_flink_compute_pool.by_name[pool_name].id
      rest_endpoint = data.confluent_flink_region.by_region[data.confluent_flink_compute_pool.by_name[pool_name].region].rest_endpoint
      # Usar endpoint privado desde variable, con fallback a público si no se proporciona
      private_rest_endpoint = var.flink_private_rest_endpoint != "" ? var.flink_private_rest_endpoint : data.confluent_flink_region.by_region[data.confluent_flink_compute_pool.by_name[pool_name].region].rest_endpoint
    }
  }
  
  # Crear lista ordenada de claves DDL y DML para depends_on
  # Esto asegura el orden de ejecución: DDL primero, luego DML
  ddl_keys = sort(keys(local.ddl_map))
  dml_keys = sort(keys(local.dml_map))
}

# =============================================================================
# RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# DDL Statements (Data Definition Language) - Usando recursos nativos de Terraform
# -----------------------------------------------------------------------------
# IMPORTANTE: Este recurso usa el nombre del archivo como clave en for_each.
# 
# REGLA CRÍTICA: El campo 'statement-name' en el YAML NO debe cambiarse después
# de la creación inicial. Si cambias el statement-name:
# - Terraform detectará el cambio en el atributo statement_name
# - El proveedor de Confluent intentará actualizar el statement con el nuevo nombre
# - Esto puede causar errores o crear un statement duplicado
# 
# CÓMO FUNCIONA LA ACTUALIZACIÓN:
# - Si solo cambias el SQL (campo 'statement'): Terraform detectará el cambio
#   y enviará una solicitud de actualización al proveedor de Confluent.
# - La clave del for_each (nombre del archivo) permanece igual, por lo que
#   Terraform identifica el mismo recurso.
# 
# ⚠️ IMPORTANTE: El comportamiento final depende del proveedor de Confluent:
# - El proveedor puede actualizar el statement in-place (preservando offsets)
# - O puede destruir y recrear el statement (perdiendo offsets)
# - Esto NO lo controla Terraform, sino la implementación del proveedor
# 
# Para verificar el comportamiento, ejecuta 'terraform plan' después de un cambio
# y revisa si propone 'update in-place' o 'destroy and recreate'.
# Ver también: VERIFY_PROVIDER_BEHAVIOR.md
# 
# Si necesitas cambiar el statement-name, debes:
# 1. Renombrar el archivo YAML (esto creará un nuevo recurso)
# 2. O eliminar el statement antiguo manualmente y crear uno nuevo
resource "confluent_flink_statement" "ddl_statements" {
  for_each = local.ddl_map
  
  statement_name = try(each.value["statement-name"], "ddl-statement-${each.key}")
  
  statement = replace(
    replace(
      each.value.statement,
      "$${catalog_name}", var.catalog_name
    ),
    "$${cluster_name}", var.cluster_name
  )
  
  stopped = try(tobool(each.value["stopped"]), false)
  
  rest_endpoint = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint
  
  compute_pool {
    id = local.compute_pools_map[each.value["flink-compute-pool"]].id
  }
  
  environment {
    id = var.environment_id
  }
  
  organization {
    id = var.organization_id
  }
  
  principal {
    id = var.principal_id
  }
  
  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }
  
  # Validación: El statement-name debe existir
  lifecycle {
    precondition {
      condition     = can(each.value["statement-name"])
      error_message = "El campo 'statement-name' es obligatorio en el archivo: ${each.key}. REGLA: NO cambies el statement-name después de la creación inicial."
    }
  }
}


# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language) - Usando recursos nativos de Terraform
# -----------------------------------------------------------------------------
# IMPORTANTE: Este recurso usa el nombre del archivo como clave en for_each.
# 
# REGLA CRÍTICA: El campo 'statement-name' en el YAML NO debe cambiarse después
# de la creación inicial. Si cambias el statement-name:
# - Terraform detectará el cambio en el atributo statement_name
# - El proveedor de Confluent intentará actualizar el statement con el nuevo nombre
# - Esto puede causar errores o crear un statement duplicado
# 
# CÓMO FUNCIONA LA ACTUALIZACIÓN:
# - Si solo cambias el SQL (campo 'statement'): Terraform detectará el cambio
#   y enviará una solicitud de actualización al proveedor de Confluent.
# - La clave del for_each (nombre del archivo) permanece igual, por lo que
#   Terraform identifica el mismo recurso.
# 
# ⚠️ IMPORTANTE: El comportamiento final depende del proveedor de Confluent:
# - El proveedor puede actualizar el statement in-place (preservando offsets)
# - O puede destruir y recrear el statement (perdiendo offsets)
# - Esto NO lo controla Terraform, sino la implementación del proveedor
# 
# Para verificar el comportamiento, ejecuta 'terraform plan' después de un cambio
# y revisa si propone 'update in-place' o 'destroy and recreate'.
# Ver también: VERIFY_PROVIDER_BEHAVIOR.md
# 
# Si necesitas cambiar el statement-name, debes:
# 1. Renombrar el archivo YAML (esto creará un nuevo recurso)
# 2. O eliminar el statement antiguo manualmente y crear uno nuevo
resource "confluent_flink_statement" "dml_statements" {
  for_each = local.dml_map
  
  statement_name = try(each.value["statement-name"], "dml-statement-${each.key}")
  
  statement = replace(
    replace(
      each.value.statement,
      "$${catalog_name}", var.catalog_name
    ),
    "$${cluster_name}", var.cluster_name
  )
  
  stopped = try(tobool(each.value["stopped"]), false)
  
  rest_endpoint = local.compute_pools_map[each.value["flink-compute-pool"]].private_rest_endpoint
  
  compute_pool {
    id = local.compute_pools_map[each.value["flink-compute-pool"]].id
  }
  
  environment {
    id = var.environment_id
  }
  
  organization {
    id = var.organization_id
  }
  
  principal {
    id = var.principal_id
  }
  
  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }
  
  # Validación: El statement-name debe existir
  lifecycle {
    precondition {
      condition     = can(each.value["statement-name"])
      error_message = "El campo 'statement-name' es obligatorio en el archivo: ${each.key}. REGLA: NO cambies el statement-name después de la creación inicial."
    }
  }
  
  # Asegurar orden de ejecución: DML statements se ejecutan después de todos los DDL
  # Usamos depends_on con todos los recursos DDL para garantizar el orden
  depends_on = [confluent_flink_statement.ddl_statements]
}