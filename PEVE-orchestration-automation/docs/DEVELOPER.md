# Cómo trabajar este repo

Aquí solo Terraform/scripts. YAML en PEVE-orchestration-resources. Actions en PEVE-eda-workflows-develop-v2.

`dev` / `cert` / `prod` son carpetas del YAML, no ramas de este repo.

```bash
export EXTERNO=/ruta/PEVE-orchestration-resources
export CODAPP=PEVE
export ENV_FOLDER=dev
export TF_VAR_temporal_cloud_api_key=...
make test
make lint
./scripts/local/tf.sh temporal-cloud plan
```

No cambies el `name` de un namespace ya aplicado (ForceNew). Tampoco `regions`.

Search attributes, SA, users, Nexus, `labels`/`tags` y auth (API key o mTLS+CA en Vault) van en el mismo apply si están en el YAML de ese env. Los tags de Temporal van en minúsculas (máx. 10). mTLS: `VAULT_ADDR` + `VAULT_TOKEN`; `tf.sh` corre `fetch-temporal-ca-vault.sh`.

Campos y valores para equipos de app: `PEVE-orchestration-resources/docs/NAMESPACE.md` y `docs/NEXUS.md`.
