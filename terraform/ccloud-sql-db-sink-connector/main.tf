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
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.20.0"
    }
  }
}

# =============================================================================
# PROVIDERS CONFIGURATION
# =============================================================================
provider "vault" {
  address = var.vault_addr
  # VAULT_TOKEN se obtiene via OIDC en GitHub Actions o se exporta localmente
}

provider "confluent" {
  cloud_api_key    = local.confluent_cloud_api_key
  cloud_api_secret = local.confluent_cloud_api_secret
}

# =============================================================================
# VAULT DATA SOURCES
# =============================================================================
data "vault_kv_secret_v2" "confluent" {
  mount = var.vault_kv_mount
  name  = var.vault_secret_path
}

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Confluent Cloud API credentials
  confluent_cloud_api_key    = try(data.vault_kv_secret_v2.confluent.data["cloud_api_key"], null)
  confluent_cloud_api_secret = try(data.vault_kv_secret_v2.confluent.data["cloud_api_secret"], null)
  
  # Service account information
  service_account_id = try(data.vault_kv_secret_v2.confluent.data["service_account_id"], null)
  
  # Cargar configuración del conector desde archivo JSON
  connector_config = try(jsondecode(file(var.connector_config_path)), {})
  
  # Combinar configuración base con variables
  final_config = merge(
    local.connector_config.config_nonsensitive,
    {
      "kafka.service.account.id" = local.service_account_id
      "topics"                   = var.topic_name
      "connection.username"      = var.sql_username
      "connection.password"      = var.sql_password
    }
  )
}

# =============================================================================
# RESOURCES
# =============================================================================
resource "confluent_connector" "sql_sink" {
  environment {
    id = var.environment_id
  }

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  config_sensitive = {
    "connection.username" = var.sql_username
    "connection.password" = var.sql_password
  }

  config_nonsensitive = local.final_config

  status = var.connector_status
}