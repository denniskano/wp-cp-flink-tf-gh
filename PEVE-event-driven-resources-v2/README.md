# PEVE-event-driven-resources-v2

Repo de **workflows** (GitHub Actions). No contiene Terraform ni YAML de aplicación.

No confundir con `flink-v2/PEVE-event-driven-resources-v2` (copia vieja: Actions + Terraform mezclados, codegen `gen_*_dinamic.sh`).

## Cinco repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** | Terraform. Checkout → `./iac` (`IAC_REF` = tag o rama) |
| **PEVE-event-driven-resources-v2** (este) | GitHub Actions |
| **PEVE-kafka-connect-resources-v1** | YAML Connect → `./externo` |
| **PEVE-stream-processing-resources-v2** | YAML Flink → `./externo` |
| **PEVE-event-driven-resources-v3** | YAML core (topics, schemas, RBAC/SA) → `./externo` |

## Workflows

**Cinco repos (cableados):** `deploy-kafka-connect.yml` (DES), `deploy-kafka-connect-cert.yml`, `deploy-kafka-connect-prod.yml`, `deploy-connect-plugins.yml` (DES), `deploy-compute-pools-desa-2-0.yml`, `deploy-flink-statements-desa-2-0.yml`, `peve-resources-desa.yml`.

**Copia original develop-v2 (aún checkout viejo / `BRANCH_AUTOMATION`):** `peve-resources-{cert,prod}.yml`, `peve-catalog-mgmt-*`, `deploy-compute-pools-{desa,cert,prod}.yml` (sin `-2-0`), `deploy-flink-statements-{desa,cert,prod}.yml` (sin `-2-0`), `ccloud-create-sa-apikey-*`, `conector-mqzos-*`, `cp-*-sr-exporter.yml`, `peve-util-*`.

Actions originales copiadas: `eda-resources`, `eda-schema-registry`, `eda-catalog-mgmt`.

`IAC_REF` (env del workflow) pinnea el IaC. En producción usar un **tag**, no `main` flotante.

## Connect (implementado)

Orden del job (`plan` / `apply` / `pause` / `resume`; no hay `destroy`):

1. Checkout IaC → `./iac` y resources → `./externo`
2. `validate-yaml.sh` (existen `connects/*.yaml` y `security/*.yaml`)
3. Vault
4. `terraform -chdir=./iac/stacks/kafka-connect`

State: DES `dev/{CODAPP}/{use_case}/tf-connect.tfstate` (`tf-connect-dev`). CERT `cert/…` (`tf-connect-cert`). PROD `prod/…` (`tf-connect-prod`). YAML en `{CODAPP}/{desa|cert|prod}/{use-case}/`. `IAC_REF` de cert/prod tiene que ser un **tag**.

Custom SMT (`deploy-connect-plugins`, **antes** que `deploy-kafka-connect`):

1. Checkout IaC → `./iac` y resources → `./externo`
2. `validate-smt.sh` (`{CODAPP}/desa/smt.yaml`; si falta, el job falla)
3. Vault: Confluent + ARM
4. `curl` anónimo de cada `artifacts[].url` (igual que el CD Jenkins) → `TF_VAR_artifact_files`
5. `terraform -chdir=./iac/stacks/connect-plugins`

State DES: `dev/{CODAPP}/connect-plugins/tf-connect-plugins.tfstate` (no reutiliza `tf-connect.tfstate`). El apply imprime `artifact_ids` (`ca-…`) para pegar en el YAML del conector.

Uso (declarar, pegar el `ca-…`, nueva versión, borrar): `TEMPLATE/docs/smt.md` en kafka-connect-resources-v1. No hay `destroy`; sacar un `name` de `smt.yaml` y apply elimina el artifact.

## Flink DES (jobs de v2, cinco repos)

Misma forma PREPARE + CI + CD. Checkouts:

- Este repo → actions (`single-encrypt` / `single-decrypt` / `install-yq`)
- `PEVE-event-driven-automation` @ `IAC_REF` → `./iac`
- `PEVE-stream-processing-resources-v2` → `./externo`
- Codegen: `iac/resources` → `./resources`, `gen_*` → `./scripts`
- `-chdir`: `iac/stacks/flink-compute-pool` o `iac/stacks/flink-statements`

State pools: `dev/{CODAPP}/ccloud-flink/compute-pool/tf-flink-cps.tfstate`.  
State statements: `dev/{CODAPP}/ccloud-flink/{pipeline}/tf-flink-rbacs-stmts.tfstate`.

## eda-core DES

Misma forma PREPARE + CI + CD (tres recursos en paralelo: topics, schema-registry, RBAC).

- IaC → `./iac`; YAML v3 → `./externo`
- Action `eda-core-task`: copia `stacks/eda-core` + templates core → `./automation` y corre `scripts/terraform_task.sh`
- YAML: `./externo/{CODAPP}/desa/{topics|security|governance|asyncapi}/`
- State: container `tf-peve-resources`, key `DESA/{CODAPP}/cc/tf-*.tfstate` (`terraform_task.sh` pone `ENV` en mayúsculas)

Terraform **1.12.2** (pin del `providers.tf` de core). Sin YAML que matchee `cc-*-topics.yaml` / `sr-*-subjects.yaml` / `cc-*-rbac-des.yaml` el script sale 0.

## Actions locales

`single-encrypt` / `single-decrypt` (token GitHub App entre jobs), `install-yq`.
