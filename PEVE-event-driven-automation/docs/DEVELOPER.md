# Cómo trabajar este repo

Acá solo va Terraform (módulos, stacks, scripts, tests). El YAML de la app y los Actions se tocan en los otros repos.

`desa` / `cert` / `prod` no son ramas de este repo. Son carpetas en resources + otra key de state + otro workflow.

## Qué entra y qué no

Sí: `modules/ccloud-*` (sin backend ni `provider "confluent"`), `stacks/<nombre>/` con backend Azure, scripts que llama GHA o `make`, fixtures, docs.

No: `.github/`, YAML `{CODAPP}/desa/...`, JAR de SMT/UDF, tfstate, tfvars con secretos. Un apply = un stack.

## Módulo vs stack

```
modules/ccloud-foo/     # lógica. versions.tf, sin backend
stacks/foo/             # providers.tf (azurerm + confluent), module source = ../../modules/...
```

El job hace `terraform -chdir=./iac/stacks/foo`. Si no tiene backend, no es un stack.

Flink y eda-core no siguen del todo ese esquema: el HCL lo escriben los `gen_*` / `generate_*` sobre `resources/template/`. Los `.tf` generados no se commitean (`.gitignore`).

## Si ya está aplicado

- Variable nueva: módulo + stack + `TF_VAR_*` en el workflow.
- No cambies la key del `for_each` de un resource que ya existe (en Connect es el filename sin `.yaml`). Eso es destroy+create.
- Si mueves el address (`confluent_connector.connectors` → `module.connectors....`) hace falta `moved` o `state mv`. Si no, el primer apply recrea en Confluent.
- Guard de Connect: `for_each` vacío destruye los conectores del use-case. El workflow pone `allow_empty_connectors=true` solo cuando `connects/` no tiene YAML (borrado a propósito). Si hay YAML, el guard sigue bloqueando un apply vacío.
- RBAC: un `resource_type` inventado tiene que fallar.
- Pin de Terraform/provider: en el stack. El módulo pone el mínimo.

Connect que venía de flink-v1: las addresses quedan `module.connectors.confluent_connector.connectors["…"]`. El plan de corte va contra el mismo blob `tf-connect.tfstate` y 0 destroy, salvo que el ticket lo pida.

## Flink y eda-core (codegen)

Antes del plan, el job (y `scripts/local/tf.sh`) corre:

```
scripts/gen_cp_flink_dinamic.sh          → stacks/flink-compute-pool/cp_flink.tf
scripts/gen_rbac_flink_dinamic.sh        → rbac_flink.tf + data_sa_flink.tf
scripts/gen_stmt_flink_dinamic.sh        → stmt_flink.tf + data_cp_flink.tf
                                        # un apply: DDL + DML. rest solo Private Link
```

Buscan `./resources/template` desde el cwd; el workflow copia `iac/resources` → `./resources`. `gen_rbac` necesita `CC_SR_PROPERTIES_ID`, `CC_SR_PROPERTIES` y `HV_PEVE_SECRETS`.

eda-core:

```
generate_topic_dinamic.sh
generate_schema_registry_dinamic.sh
generate_rbac_dinamic.sh
terraform_task.sh          # -chdir=./automation
```

El action `eda-core-task` copia `stacks/eda-core` + los tpl a `./automation`. Los scripts hablan de `./automation` a propósito.

SA del use-case: eda-core. Custom SMT: `{CODAPP}/{env}/smt.yaml` → `deploy-connect-plugins` (antes que `kafka-connect`). El JAR lo baja el workflow; no se versiona acá. Statements no suben UDF ni crean connections.

Si llenas un stack vacío, copia `ccloud-connectors` + `kafka-connect`, actualiza STACKS.md / STATE.md (key **nueva**) y avisa: hace falta otro workflow con otro `-chdir` y otra key.

## Convenciones

`for_each` por nombre de archivo, no por índice. `terraform fmt` en el PR. Comentario solo si hay trampa (ForceNew, destroy masivo). Secretos: `sensitive = true`, Vault → `config_sensitive`. Un topic de eda-core no se vuelve a declarar en Connect.

## Pruebas

No hay CI en este repo todavía. En la laptop:

```bash
make fmt
make lint
git diff --exit-code
make test
```

`make test` corre `tests/*/run.sh` y validate de los stacks que tienen `.tf`. No habla con Confluent.

Plan de verdad (cuando toca algo ya desplegado):

```bash
export EXTERNO=/ruta/PEVE-kafka-connect-resources-v1
export CODAPP=PEVE
export USE_CASE=<carpeta>
export ENV_FOLDER=desa
make plan-connect
```

`tf.sh` no inyecta cluster id, API keys ni backend. Sin eso no es el plan de GHA. Completa `TF_VAR_*` o corre el workflow en DES con `IAC_REF` = tu rama.

Lee el plan. `replace` en `confluent_connector` recrea el conector (se pierden offsets). `-/+` en role binding corta ACL a mitad de apply. Guard o variable con default → 0 destroy / 0 replace. Si vacías el YAML, el guard tiene que fallar.

Primer intento siempre DES. CERT/PROD no.

## Ramas

Trunk: `main`. Feature: `feature/PEVE-<id>-<tema>`. Fix: `fix/PEVE-<id>-…`. No abras `desa`, `cert`, `prod` ni `develop` acá.

Cert/prod pinnean `IAC_REF` a un tag, no a `main`. DES puede apuntar a la feature un rato.

Tres lados = tres PRs: este repo (tag), el YAML, y v2 (`IAC_REF`). Si el campo es obligatorio, el mismo release.

[STACKS.md](STACKS.md) · [STATE.md](STATE.md) · [NETWORKING.md](NETWORKING.md)
