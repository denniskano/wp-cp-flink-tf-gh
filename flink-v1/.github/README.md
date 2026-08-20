# GitHub Actions CI/CD Setup

Este documento explica cómo configurar GitHub Actions para el despliegue automático de la infraestructura de Confluent Cloud Flink.

## 🔧 Configuración Requerida

### 1. Variables de Repositorio

Configura las siguientes variables en tu repositorio de GitHub:

**Settings → Secrets and variables → Actions → Repository variables**

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `VAULT_ADDR` | URL del servidor Vault | `https://vault.example.com` |
| `VAULT_JWT_PATH` | Path para autenticación JWT | `auth/jwt` |
| `VAULT_JWT_ROLE` | Rol JWT configurado en Vault | `github-actions` |

### 2. Configuración de Vault

#### Habilitar JWT Auth Method
```bash
vault auth enable jwt
```

#### Configurar JWT Auth Method
```bash
vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"
```

#### Crear Policy para GitHub Actions
```bash
vault policy write github-actions - <<EOF
path "kv/data/confluent/cloud/creds" {
  capabilities = ["read"]
}
EOF
```

#### Crear Role para GitHub Actions
```bash
vault write auth/jwt/role/github-actions \
    bound_audiences="https://github.com/your-org/your-repo" \
    bound_claims='{"repository": "your-org/your-repo"}' \
    user_claim="sub" \
    policies="github-actions" \
    ttl="1h"
```

### 3. Environment Protection

Configura un environment llamado `production` en GitHub:

**Settings → Environments → New environment**

- **Name**: `production`
- **Protection rules**: 
  - ✅ Required reviewers (opcional)
  - ✅ Wait timer (opcional)

## 🚀 Workflows Disponibles

### 1. Validación Automática
- **Trigger**: Push a `main` o `develop`
- **Acción**: Valida formato y sintaxis de Terraform

### 2. Plan en Pull Requests
- **Trigger**: Pull Request a `main`
- **Acción**: Ejecuta `terraform plan`

### 3. Despliegue Manual
- **Trigger**: Manual dispatch
- **Acciones disponibles**:
  - `plan`: Ejecuta plan de Terraform
  - `apply`: Despliega infraestructura
  - `destroy`: Destruye infraestructura

## 📋 Uso

### Despliegue Manual
1. Ve a **Actions** en tu repositorio
2. Selecciona **Confluent Cloud Flink Infrastructure**
3. Haz clic en **Run workflow**
4. Selecciona la acción (`plan`, `apply`, o `destroy`)
5. Haz clic en **Run workflow**

### Despliegue Automático
- Los cambios en `main` o `develop` ejecutan validación automática
- Los Pull Requests muestran el plan de Terraform

## 🔒 Seguridad

- ✅ Credenciales almacenadas en Vault
- ✅ Autenticación OIDC con GitHub
- ✅ Tokens temporales (TTL: 1 hora)
- ✅ Environment protection para producción
- ✅ Validación de formato y sintaxis

## 🛠️ Troubleshooting

### Error: "Vault authentication failed"
- Verifica que `VAULT_ADDR`, `VAULT_JWT_PATH`, y `VAULT_JWT_ROLE` estén configurados
- Confirma que el JWT auth method esté habilitado en Vault

### Error: "Terraform plan failed"
- Verifica que las credenciales en Vault sean válidas
- Confirma que el service account tenga los permisos necesarios

### Error: "Environment protection rules"
- Asegúrate de que el environment `production` esté configurado
- Verifica que tengas permisos para aprobar el deployment
