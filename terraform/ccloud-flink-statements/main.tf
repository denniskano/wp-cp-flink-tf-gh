# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

# =============================================================================
# PROVIDERS CONFIGURATION
# =============================================================================
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# =============================================================================
# DATA SOURCES
# =============================================================================
data "confluent_organization" "current" {}

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
  
  cloud  = "AZURE"
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
  
  # Service Account ID
  principal_id = var.principal_id
  
  # Cargar archivos YAML de DDL y DML
  ddl_files = fileset("${var.statements_dir}/ddl", "*.yaml")
  ddl_data  = [for f in local.ddl_files : yamldecode(file("${var.statements_dir}/ddl/${f}"))]
  
  dml_files = fileset("${var.statements_dir}/dml", "*.yaml")
  dml_data  = [for f in local.dml_files : yamldecode(file("${var.statements_dir}/dml/${f}"))]
  
  # Extraer compute pools únicos de los archivos YAML
  all_compute_pools = distinct(concat(
    [for ddl in local.ddl_data : ddl["flink-compute-pool"]],
    [for dml in local.dml_data : dml["flink-compute-pool"]]
  ))
  
  # Mapeo de compute pools (necesario para asociar statements con compute pools)
  compute_pools_map = {
    for pool_name in local.all_compute_pools :
    pool_name => {
      id = data.confluent_flink_compute_pool.by_name[pool_name].id
      rest_endpoint = data.confluent_flink_region.by_region[data.confluent_flink_compute_pool.by_name[pool_name].region].rest_endpoint
    }
  }
}

# =============================================================================
# RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# DDL Statements (Data Definition Language) - Usando null_resource con CLI
# -----------------------------------------------------------------------------
resource "null_resource" "ddl_statements" {
  count = length(local.ddl_data)

  triggers = {
    statement_name = local.ddl_data[count.index]["statement-name"]
    statement      = local.ddl_data[count.index].statement
    compute_pool   = local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      export CONFLUENT_CLOUD_API_KEY=${local.confluent_flink_api_key}
      export CONFLUENT_CLOUD_API_SECRET=${local.confluent_flink_api_secret}
      
      # Configurar credenciales de Flink en archivo de configuración
      mkdir -p ~/.confluent
      echo "[api]" > ~/.confluent/config
      echo "api_key = ${local.confluent_flink_api_key}" >> ~/.confluent/config
      echo "api_secret = ${local.confluent_flink_api_secret}" >> ~/.confluent/config
      
      # Verificar si el statement ya existe
      if confluent flink statement list --environment ${var.environment_id} --compute-pool ${local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].id} 2>/dev/null | grep -q "${local.ddl_data[count.index]["statement-name"]}"; then
        echo "Statement '${local.ddl_data[count.index]["statement-name"]}' ya existe, saltando..."
      else
        echo "Creando statement DDL: ${local.ddl_data[count.index]["statement-name"]}"
        echo "Debug - URL a usar: ${local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].rest_endpoint}"
        confluent flink statement create "${local.ddl_data[count.index]["statement-name"]}" \
          --sql "${replace(local.ddl_data[count.index].statement, "\n", " ")}" \
          --environment ${var.environment_id} \
          --compute-pool ${local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].id} \
          --url ${local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].rest_endpoint}
      fi
    EOT
  }
}

# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language) - Usando null_resource con CLI
# -----------------------------------------------------------------------------
resource "null_resource" "dml_statements" {
  count = length(local.dml_data)

  triggers = {
    statement_name = local.dml_data[count.index]["statement-name"]
    statement      = local.dml_data[count.index].statement
    compute_pool   = local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].id
    stopped        = local.dml_data[count.index].stopped
  }

  provisioner "local-exec" {
    command = <<-EOT
      export CONFLUENT_CLOUD_API_KEY=${local.confluent_flink_api_key}
      export CONFLUENT_CLOUD_API_SECRET=${local.confluent_flink_api_secret}
      
      # Configurar credenciales de Flink en archivo de configuración
      mkdir -p ~/.confluent
      echo "[api]" > ~/.confluent/config
      echo "api_key = ${local.confluent_flink_api_key}" >> ~/.confluent/config
      echo "api_secret = ${local.confluent_flink_api_secret}" >> ~/.confluent/config
      
      # Verificar si el statement ya existe
      if confluent flink statement list --environment ${var.environment_id} --compute-pool ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].id} 2>/dev/null | grep -q "${local.dml_data[count.index]["statement-name"]}"; then
        echo "Statement '${local.dml_data[count.index]["statement-name"]}' ya existe, saltando..."
      else
        echo "Creando statement DML: ${local.dml_data[count.index]["statement-name"]}"
        echo "Debug - URL a usar: ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].rest_endpoint}"
        confluent flink statement create "${local.dml_data[count.index]["statement-name"]}" \
          --sql "${replace(local.dml_data[count.index].statement, "\n", " ")}" \
          --environment ${var.environment_id} \
          --compute-pool ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].id} \
          --url ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].rest_endpoint}
        
        # Si el statement debe estar pausado, pausarlo
        if [ "${local.dml_data[count.index].stopped}" = "true" ]; then
          echo "Pausando statement: ${local.dml_data[count.index]["statement-name"]}"
          confluent flink statement pause "${local.dml_data[count.index]["statement-name"]}" --environment ${var.environment_id} --compute-pool ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].id} --url ${local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].rest_endpoint} || true
        fi
      fi
    EOT
  }

  # Dependencia: DML statements se ejecutan después de DDL
  depends_on = [null_resource.ddl_statements]
}