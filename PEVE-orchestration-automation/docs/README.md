# Repos Temporal Cloud

| Repo | Qué hay |
|---|---|
| PEVE-orchestration-automation (este) | Terraform, scripts, tests |
| PEVE-orchestration-resources | YAML `{CODAPP}/{dev\|cert\|prod}/namespaces` + `nexus` |
| PEVE-eda-workflows-develop-v2 | GitHub Actions `deploy-temporal-*` |

El job: checkout IAC → `./iac`, YAML → `./externo`, `validate-temporal-yaml.sh`, Vault, `terraform -chdir=./iac/stacks/temporal-cloud`.

Auth de namespace: **solo `api_key_auth`**. Las API keys de workers salen como output sensible y el CD las escribe a Vault.

Ver [TEMPORAL-HA.md](TEMPORAL-HA.md), [PRIVATELINK.md](PRIVATELINK.md), [STATE.md](STATE.md), [VAULT.md](VAULT.md).
