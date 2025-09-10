#!/bin/bash

# =============================================================================
# CREDENTIALS SETUP SCRIPT
# =============================================================================
# Este script ayuda a configurar las credenciales en Vault

set -e

VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
SECRET_PATH=${SECRET_PATH:-"confluent/cloud/creds"}

echo "🔐 Configurando credenciales en Vault..."
echo "Vault URL: $VAULT_ADDR"
echo "Secret Path: kv/$SECRET_PATH"

# Verificar que Vault esté ejecutándose
if ! vault status >/dev/null 2>&1; then
    echo "❌ Error: Vault no está ejecutándose en $VAULT_ADDR"
    echo "Inicia Vault con: vault server -dev"
    exit 1
fi

echo "✅ Vault está ejecutándose"

# Función para leer input seguro
read_secret() {
    local prompt="$1"
    local var_name="$2"
    
    echo -n "$prompt: "
    read -s value
    echo
    eval "$var_name='$value'"
}

echo ""
echo "📝 Ingresa las credenciales de Confluent Cloud:"
echo ""

# Leer credenciales
read_secret "Cloud API Key" CLOUD_API_KEY
read_secret "Cloud API Secret" CLOUD_API_SECRET
read_secret "Flink API Key" FLINK_API_KEY
read_secret "Flink API Secret" FLINK_API_SECRET
read_secret "Service Account ID (sa-xxxxx)" SERVICE_ACCOUNT_ID

echo ""
echo "💾 Almacenando credenciales en Vault..."

# Almacenar en Vault
vault kv put kv/$SECRET_PATH \
    cloud_api_key="$CLOUD_API_KEY" \
    cloud_api_secret="$CLOUD_API_SECRET" \
    flink_api_key="$FLINK_API_KEY" \
    flink_api_secret="$FLINK_API_SECRET" \
    service_account_id="$SERVICE_ACCOUNT_ID"

echo "✅ Credenciales almacenadas exitosamente!"

# Verificar que se almacenaron correctamente
echo ""
echo "🔍 Verificando credenciales almacenadas..."
vault kv get -field=service_account_id kv/$SECRET_PATH >/dev/null && echo "✅ Service Account ID verificado"
vault kv get -field=cloud_api_key kv/$SECRET_PATH >/dev/null && echo "✅ Cloud API Key verificado"
vault kv get -field=flink_api_key kv/$SECRET_PATH >/dev/null && echo "✅ Flink API Key verificado"

echo ""
echo "🎉 Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Configura las variables de GitHub Actions"
echo "2. Ejecuta el script de configuración de Vault: ./scripts/setup-vault.sh"
echo "3. Haz push del código a GitHub"
echo "4. Ejecuta el workflow de GitHub Actions"
