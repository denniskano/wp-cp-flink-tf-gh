# =============================================================================
# COMPUTE POOLS CONFIGURATION
# =============================================================================
# Todas las variables se pasan dinámicamente desde GitHub Actions como TF_VAR_*
# - environment_id: desde CC_PROPERTIES
# - compute_pool_config_path: construido dinámicamente con CODAPP
# - confluent_cloud_api_key/secret: desde Vault
# =============================================================================
