# Secretos en Vault

El Account API key de Temporal (gobernanza) y el ARM del state viven en Vault. Las API keys de workers las escribe el CD después del apply.

| Uso | Path (KV v2, mount `peve/kv2`) | Campo |
|---|---|---|
| Account API key (provider Terraform) | `{dev\|cert\|prod}/peve/temporal/PEVE_GHA_TEMPORAL_CLOUD_API_KEY` | `secret` |
| Azure RM access key (state) | `{dev\|cert\|prod}/peve/ccloud/PEVE_GHA_ARM_ACCESS_KEY` | `secret` |
| GitHub App private key (checkout IAC + YAML) | `{dev\|cert\|prod}/peve/temporal/ghapp_peve_self_service_pk` | `secret` |
| API keys de workers (salida de apply) | `{dev\|cert\|prod}/{codapp}/temporal/apikeys/{display_name}` | `token` |

Vault-action lee con prefijo `peve/kv2/data/…`.

No imprimas `apikey_tokens` ni el Account API key en logs.
