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

**Cinco repos (cableados, DES):** `deploy-kafka-connect.yml`, `deploy-compute-pools-desa-2-0.yml`, `deploy-flink-statements-desa-2-0.yml`, `peve-resources-desa.yml`.

**Copia original develop-v2 (aún checkout viejo / `BRANCH_AUTOMATION`):** `peve-resources-{cert,prod}.yml`, `peve-catalog-mgmt-*`, `deploy-compute-pools-{desa,cert,prod}.yml` (sin `-2-0`), `deploy-flink-statements-{desa,cert,prod}.yml` (sin `-2-0`), `ccloud-create-sa-apikey-*`, `conector-mqzos-*`, `cp-*-sr-exporter.yml`, `peve-util-*`.

Actions originales copiadas: `eda-resources`, `eda-schema-registry`, `eda-catalog-mgmt`.

`IAC_REF` (env del workflow) pinnea el IaC. En producción usar un **tag**, no `main` flotante.

## Connect (implementado)

Orden del job cuando `action` ≠ `destroy`:

1. Checkout IaC → `./iac` y resources → `./externo`
2. `validate-yaml.sh` (existen `connects/*.yaml` y `security/*.yaml`)
3. Vault
4. `terraform -chdir=./iac/stacks/kafka-connect`

State DES: `dev/{CODAPP}/{use_case}/tf-connect.tfstate`.

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
