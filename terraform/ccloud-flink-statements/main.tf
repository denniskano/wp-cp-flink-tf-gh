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
# DDL Statements (Data Definition Language) - Usando resource nativo
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "ddl_statements" {
  count = length(local.ddl_data)
  
  statement = local.ddl_data[count.index].statement
  
  organization {
    id = var.organization_id
  }
  
  environment {
    id = var.environment_id
  }
  
  compute_pool {
    id = local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].id
  }
  
  principal {
    id = var.principal_id
  }
  
  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }
  
  rest_endpoint = local.compute_pools_map[local.ddl_data[count.index]["flink-compute-pool"]].rest_endpoint
}


# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language) - Usando resource nativo
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "dml_statements" {
  count = length(local.dml_data)
  
  statement = local.dml_data[count.index].statement
  
  organization {
    id = var.organization_id
  }
  
  environment {
    id = var.environment_id
  }
  
  compute_pool {
    id = local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].id
  }
  
  principal {
    id = var.principal_id
  }
  
  credentials {
    key    = var.confluent_flink_api_key
    secret = var.confluent_flink_api_secret
  }
  
  rest_endpoint = local.compute_pools_map[local.dml_data[count.index]["flink-compute-pool"]].rest_endpoint
  
  # Dependencia: DML statements se ejecutan después de DDL
  depends_on = [confluent_flink_statement.ddl_statements]
}