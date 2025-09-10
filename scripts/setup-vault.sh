#!/bin/bash

# =============================================================================
# VAULT SETUP SCRIPT FOR GITHUB ACTIONS
# =============================================================================
# Este script configura Vault para autenticación OIDC con GitHub Actions

set -e

# Variables
VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
GITHUB_ORG=${GITHUB_ORG:-"your-org"}
GITHUB_REPO=${GITHUB_REPO:-"your-repo"}
JWT_PATH=${JWT_PATH:-"auth/jwt"}
JWT_ROLE=${JWT_ROLE:-"github-actions"}
POLICY_NAME=${POLICY_NAME:-"github-actions"}

echo "🔧 Configurando Vault para GitHub Actions..."
echo "Vault URL: $VAULT_ADDR"
echo "GitHub Repo: $GITHUB_ORG/$GITHUB_REPO"

# Verificar que Vault esté ejecutándose
if ! vault status >/dev/null 2>&1; then
    echo "❌ Error: Vault no está ejecutándose en $VAULT_ADDR"
    echo "Inicia Vault con: vault server -dev"
    exit 1
fi

echo "✅ Vault está ejecutándose"

# 1. Habilitar JWT Auth Method
echo "🔐 Habilitando JWT Auth Method..."
vault auth enable -path=jwt jwt 2>/dev/null || echo "JWT auth method ya está habilitado"

# 2. Configurar JWT Auth Method
echo "⚙️ Configurando JWT Auth Method..."
vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"

# 3. Crear Policy para GitHub Actions
echo "📋 Creando policy para GitHub Actions..."
vault policy write $POLICY_NAME - <<EOF
path "kv/data/confluent/cloud/creds" {
  capabilities = ["read"]
}

path "kv/metadata/confluent/cloud/creds" {
  capabilities = ["read"]
}
EOF

# 4. Crear Role para GitHub Actions
echo "🎭 Creando role para GitHub Actions..."
vault write auth/jwt/role/$JWT_ROLE \
    bound_audiences="https://github.com/$GITHUB_ORG/$GITHUB_REPO" \
    bound_claims='{"repository": "'$GITHUB_ORG'/'$GITHUB_REPO'"}' \
    user_claim="sub" \
    policies="$POLICY_NAME" \
    ttl="1h"

# 5. Verificar configuración
echo "🔍 Verificando configuración..."
echo "JWT Auth Methods:"
vault auth list | grep jwt || echo "No se encontró JWT auth method"

echo "Policies:"
vault policy list | grep $POLICY_NAME || echo "No se encontró policy $POLICY_NAME"

echo "JWT Roles:"
vault read auth/jwt/role/$JWT_ROLE || echo "No se encontró role $JWT_ROLE"

echo ""
echo "✅ Configuración completada!"
echo ""
echo "📋 Variables para GitHub Repository:"
echo "VAULT_ADDR: $VAULT_ADDR"
echo "VAULT_JWT_PATH: $JWT_PATH"
echo "VAULT_JWT_ROLE: $JWT_ROLE"
echo ""
echo "🔗 Configura estas variables en:"
echo "https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
