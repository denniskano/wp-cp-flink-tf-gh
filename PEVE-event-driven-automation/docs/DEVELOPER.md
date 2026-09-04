# Cómo trabajar este repo

Acá solo va Terraform (módulos, stacks, scripts, tests). El YAML de la app y los Actions se tocan en los otros repos.

`desa` / `cert` / `prod` no son ramas de acá. Son carpetas en resources + otra key de state + otro workflow. Este repo versiona código, no entornos.

## Qué entra y qué no

Sí: `modules/ccloud-*` (sin backend ni `provider "confluent"`), `stacks/<nombre>/` con backend Azure, scripts que llame GHA o `make`, fixtures en `tests/`, docs.

No: `.github/`, YAML `{CODAPP}/desa/...`, `domains/` partidos por create/delete, `config/development|certification|production`, JAR de SMT/UDF, tfstate, tfvars con secretos. Tampoco un segundo stack en el mismo apply.

## Módulo vs stack

```
modules/ccloud-foo/     # lógica. versions.tf, sin backend
stacks/foo/             # providers.tf (azurerm + confluent), variables, module source = ../../modules/...
```

El job hace `terraform -chdir=./iac/stacks/foo`. Si no tiene backend, no es un stack.

Flink y eda-core no siguen del todo ese dibujo: el HCL lo escriben los `gen_*` / `generate_*` sobre templates en `resources/template/`. Los `.tf` generados no se commitean (ver `.gitignore`).

## Cambiar algo que ya está aplicado

- Variable nueva: módulo + stack + cómo llega (`TF_VAR_*` en el workflow).
- No cambies la key del `for_each` de un resource que ya existe (en Connect es el filename sin `.yaml`). Eso es destroy+create.
- Si movés un resource de address (`confluent_connector.connectors` → `module.connectors....`) hace falta `moved` o `state mv`. Si no, el primer apply recrea en Confluent.
- Guards (`precondition`): si un `for_each` vacío te puede borrar prod, el plan tiene que fallar salvo un flag que setea el workflow, no el YAML.
- RBAC: un `resource_type` inventado no puede pasar callado.
- El pin de Terraform/provider va en el stack. El módulo pone el mínimo.

Connect ya aplicado desde flink-v1: las addresses pasan a `module.connectors.confluent_connector.connectors["…"]`. El plan de corte tiene que ser contra el mismo blob `tf-connect.tfstate` y 0 destroy de connector/binding, salvo que el ticket lo pida.

## Flink y eda-core (codegen)

El job (y `scripts/local/tf.sh`) corre esto **antes** del plan:

```
scripts/gen_cp_flink_dinamic.sh          → stacks/flink-compute-pool/cp_flink.tf
scripts/gen_rbac_flink_dinamic.sh        → rbac_flink.tf + data_sa_flink.tf
scripts/gen_stmt_flink_dinamic.sh        → stmt_flink.tf + data_cp_flink.tf
```

Los tres scripts son los de v2. Buscan `./resources/template` desde el cwd; por eso el workflow copia `iac/resources` → `./resources`. `gen_rbac` necesita `CC_SR_PROPERTIES_ID`, `CC_SR_PROPERTIES` y `HV_PEVE_SECRETS`.

eda-core:

```
generate_topic_dinamic.sh
generate_schema_registry_dinamic.sh
generate_rbac_dinamic.sh
terraform_task.sh          # -chdir=./automation
```

El action `eda-core-task` copia `stacks/eda-core` + los tpl core a `./automation`. Los scripts siguen hablando de `./automation` a propósito.

SA del use-case: eda-core. Connect no sube SMT (eso sería `connect-plugins`). Statements no suben UDF ni crean connections.

Si llenás un stack que hoy está vacío, copiá el patrón de `ccloud-connectors` + `kafka-connect`, actualizá STACKS.md / STATE.md (key **nueva**) y avisá: hace falta otro workflow con otro `-chdir` y otro backend key.

## Convenciones

`for_each` por nombre de archivo, no por índice. `terraform fmt` en el PR. Comentarios solo si hay una trampa (ForceNew, destroy masivo). Secretos: `sensitive = true`, Vault → `config_sensitive`. Un topic que ya crea eda-core no se vuelve a declarar en Connect.

## Pruebas

No hay CI en este repo todavía. Como mínimo, en la laptop:

```bash
make fmt
make lint
git diff --exit-code
make test
```

`make test` corre los `tests/*/run.sh` y validate de los stacks que tienen `.tf`. No habla con Confluent.

Si tocaste otro stack:

```bash
cd stacks/<stack>
terraform init -backend=false -input=false
terraform validate
terraform fmt -check
```

Hay pre-commit (`.pre-commit-config.yaml`) si lo querés. No reemplaza lo de arriba.

Plan real (cuando el cambio pega a algo ya desplegado):

```bash
export EXTERNO=/ruta/PEVE-kafka-connect-resources-v1
export CODAPP=PEVE
export USE_CASE=<carpeta>
export ENV_FOLDER=desa
make plan-connect
```

`tf.sh` no inyecta cluster id, API keys ni backend. Sin eso no es el plan de GHA. Completá `TF_VAR_*` o, más fácil, corré el workflow en DES con `IAC_REF` = tu rama.

Leé el plan. `replace` en `confluent_connector` recrea el conector (se pierden offsets). `-/+` en role binding corta ACL a mitad de apply. Si el PR solo mete un guard o una variable con default, tiene que salir 0 destroy / 0 replace. Si vaciás el YAML, el guard tiene que fallar; no listar diez destroys.

En DES: plan de un use-case de prueba, apply si cierra, mirar Confluent. Pause/resume es override in-place; el apply siguiente vuelve al `status` del YAML. No uses CERT/PROD para el primer try.

## Ramas y tags

Trunk acá es `main`. Features: `feature/PEVE-<id>-<tema>`. Fixes: `fix/PEVE-<id>-…`. No abras `desa`, `cert`, `prod` ni `develop` en este repo.

```bash
git checkout main && git pull
git checkout -b feature/PEVE-5321-connect-group-rbac
# ... pruebas, PR a main
git tag -a v1.2.0 -m "kafka-connect: guard security vacío"
git push origin v1.2.0
```

En v2, `IAC_REF` de cert/prod tiene que ser un tag, no `main` flotante. DES puede apuntar un rato a la feature para el plan.

Semver a ojo: major si hay replace inevitable, cambio de address sin `moved` o key de state distinta. Minor si agregás recurso opt-in o stack. Patch: guard, mensaje, docs.

Hotfix: rama `fix/…` desde `main` (o desde el tag que sigue usando cert), merge, tag, bump de `IAC_REF` DES → cert → prod. Si existe `release/v1.2`, cherry-pick ahí y merge de vuelta a `main`.

Un cambio que toca los tres lados suele ser tres PRs: este repo (tag), el YAML, y v2 (`IAC_REF`). Si el módulo tiene default, el YAML puede ir después. Si el campo es obligatorio, el mismo release.

## Antes del review

- El diff no mete workflows ni YAML de app.
- `make lint` y `make test` en verde.
- Si cambió el contrato Connect, actualizá las plantillas en PEVE-kafka-connect-resources-v1.
- Pensá addresses / `for_each` (¿va a haber replace?).
- Variable nueva documentada para el que toca el workflow.
- STACKS.md / STATE.md si hay stack o key nueva.
- Plan en DES sin destroy, salvo que el ticket lo autorice.

## Links

[../README.md](../README.md) · [README.md](README.md) · [STACKS.md](STACKS.md) · [STATE.md](STATE.md) · [NETWORKING.md](NETWORKING.md) · [../tests/README.md](../tests/README.md)
