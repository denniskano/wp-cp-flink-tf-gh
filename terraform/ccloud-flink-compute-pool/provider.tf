# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">= 2.7.0"
    }
  }
}

# =============================================================================
# CONFLUENT CLOUD PROVIDER
# =============================================================================

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}
