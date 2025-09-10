# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Separar archivos DDL y DML basado en el patrón de nombres
  ddl_files = toset(fileset(var.statements_dir, "ddl*.sql"))
  dml_files = toset(fileset(var.statements_dir, "dml*.sql"))
}

# =============================================================================
# RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# DDL Statements (Data Definition Language)
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "ddl" {
  for_each = local.ddl_files

  statement_name = "${var.statement_name_prefix}ddl-${replace(basename(each.value), ".sql", "")}"

  environment {
    id = var.environment_id
  }

  compute_pool {
    id = var.compute_pool_id
  }

  organization {
    id = var.organization_id
  }

  principal {
    id = var.principal_id
  }

  credentials {
    key    = var.api_key
    secret = var.api_secret
  }

  rest_endpoint = var.flink_rest_endpoint
  statement     = trimspace(file(join("/", [var.statements_dir, each.value])))
}

# -----------------------------------------------------------------------------
# DML Statements (Data Manipulation Language)
# -----------------------------------------------------------------------------
resource "confluent_flink_statement" "dml" {
  for_each = local.dml_files

  statement_name = "${var.statement_name_prefix}dml-${replace(basename(each.value), ".sql", "")}"

  environment {
    id = var.environment_id
  }

  compute_pool {
    id = var.compute_pool_id
  }

  organization {
    id = var.organization_id
  }

  principal {
    id = var.principal_id
  }

  credentials {
    key    = var.api_key
    secret = var.api_secret
  }

  rest_endpoint = var.flink_rest_endpoint
  statement     = trimspace(file(join("/", [var.statements_dir, each.value])))

  # Dependencia: DML statements se ejecutan después de DDL
  depends_on = [confluent_flink_statement.ddl]
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "ddl_statements" {
  description = "Lista de statements DDL aplicados exitosamente"
  value       = [for k, v in confluent_flink_statement.ddl : v.statement_name]
  sensitive   = false
}

output "dml_statements" {
  description = "Lista de statements DML aplicados exitosamente"
  value       = [for k, v in confluent_flink_statement.dml : v.statement_name]
  sensitive   = false
}

output "all_statements" {
  description = "Lista completa de todos los statements aplicados"
  value = concat(
    [for k, v in confluent_flink_statement.ddl : v.statement_name],
    [for k, v in confluent_flink_statement.dml : v.statement_name]
  )
  sensitive = false
}
