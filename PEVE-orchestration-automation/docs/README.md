# Repos Temporal Cloud

| Repo | Qué hay |
|---|---|
| PEVE-orchestration-automation (este) | Terraform, scripts, tests |
| PEVE-orchestration-resources | YAML `{CODAPP}/{dev\|cert\|prod}/namespaces` + `nexus` |
| PEVE-eda-workflows-develop-v2 | GitHub Actions `deploy-temporal-*` |

El job: checkout IAC → `./iac`, YAML → `./externo`, `validate-temporal-yaml.sh`, Vault, `terraform -chdir=./iac/stacks/temporal-cloud`.

Auth de namespace: **API key** (`api_key_auth: true`, default) o **mTLS** (`false` + CA en Vault). Las API keys de workers (modo API key) salen como output sensible y el CD las escribe a Vault. La CA mTLS la baja el CD de Vault a un `.pem` temporal; la clave privada del client cert **no** va en este IAC.

Ver [TEMPORAL-HA.md](TEMPORAL-HA.md), [PRIVATELINK.md](PRIVATELINK.md), [STATE.md](STATE.md), [VAULT.md](VAULT.md).
