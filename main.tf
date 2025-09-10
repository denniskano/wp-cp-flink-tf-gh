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
  # Confluent Cloud API credentials (for compute pool management)
  confluent_cloud_api_key    = try(data.vault_kv_secret_v2.confluent.data["cloud_api_key"], null)
  confluent_cloud_api_secret = try(data.vault_kv_secret_v2.confluent.data["cloud_api_secret"], null)
  
  # Confluent Flink API credentials (for statement management)
  confluent_flink_api_key    = try(data.vault_kv_secret_v2.confluent.data["flink_api_key"], null)
  confluent_flink_api_secret = try(data.vault_kv_secret_v2.confluent.data["flink_api_secret"], null)
  
  # Service account information
  service_account_id = try(data.vault_kv_secret_v2.confluent.data["service_account_id"], null)
}

# =============================================================================
# MODULES
# =============================================================================

# -----------------------------------------------------------------------------
# Flink Compute Pool Module
# -----------------------------------------------------------------------------
module "compute_pool" {
  source = "./modules/compute_pool"

  environment_id          = var.confluent_environment_id
  cloud                   = var.confluent_cloud
  region                  = var.confluent_region
  compute_pool_name       = var.compute_pool_name
  compute_pool_config_path = var.compute_pool_config_path
}

# -----------------------------------------------------------------------------
# Flink Statements Module
# -----------------------------------------------------------------------------
module "flink_statements" {
  source = "./modules/terraform-ccloud-flink-statement"

  environment_id        = var.confluent_environment_id
  compute_pool_id       = module.compute_pool.compute_pool_id
  statements_dir        = var.statements_dir
  statement_name_prefix = var.statement_name_prefix
  flink_rest_endpoint   = var.flink_rest_endpoint
  organization_id       = var.confluent_organization_id
  principal_id          = var.confluent_principal_id
  api_key               = local.confluent_flink_api_key
  api_secret            = local.confluent_flink_api_secret
}
