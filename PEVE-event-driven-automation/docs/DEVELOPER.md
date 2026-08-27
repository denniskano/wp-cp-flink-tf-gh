# Manual del developer y del automatizador

Cómo implementar Terraform en **este** repositorio, qué pruebas correr y cómo versionar con ramas y tags.

El YAML de conectores/Flink y los GitHub Actions **no** se editan aquí. Ver [README.md](README.md) del contrato entre repos.

| Rol | Trabaja en | No hace aquí |
|---|---|---|
| **Developer (IaC)** | `modules/`, `stacks/`, `scripts/`, `docs/` | YAML de app, workflows |
| **Automatizador** | Pin de `IAC_REF` en el repo de workflows, runners, backend Azure | Lógica de `for_each` / CRN |
| **App team** | Repo de resources (`connects/`, `security/`, statements) | Este repo |

`desa` / `cert` / `prod` **no son ramas de este repo**. Son carpetas en resources + key de tfstate + workflow. Este repo versiona **código Terraform**, no entornos.

---

## 1. Qué puede y qué no puede entrar

**Sí**

- Módulos en `modules/ccloud-*` (sin `backend` ni `provider "confluent"`).
- Stacks en `stacks/<nombre>/` (backend Azure RM + provider + `module` que apunta a `../../modules/...`).
- Scripts invocables por GHA o `make`.
- Documentación del contrato.

**No**

- `.github/workflows/`
- YAML `{CODAPP}/desa/...`
- JAR/ZIP de SMT o UDF
- `*.tfstate`, `*.tfvars` con secretos, `.env`
- Un segundo stack dentro del mismo `apply` (un stack = un tfstate = un workflow)

Mapa de stacks: [STACKS.md](STACKS.md). Keys de state: [STATE.md](STATE.md).

---

## 2. Cómo agregar código de forma correcta

### 2.1 Anatomía obligatoria

```
modules/ccloud-foo/     # lógica; versions.tf con required_providers; SIN backend
  main.tf
  variables.tf
  outputs.tf
  versions.tf
  README.md

stacks/foo/             # raíz ejecutable
  providers.tf          # terraform { backend "azurerm" {} } + provider "confluent"
  variables.tf          # incluye API keys (sensitive); el módulo no las declara
  main.tf               # module "x" { source = "../../modules/ccloud-foo" }
  outputs.tf            # reexporta lo del módulo
  README.md
```

El workflow hará `terraform -chdir=./iac/stacks/foo`. Si el código nuevo no es una raíz con backend, **no es un stack**.

### 2.2 Cambiar un módulo que ya existe (ej. `ccloud-connectors`)

1. Rama desde `main` (ver [ciclo de ramas](#5-ciclo-de-vida-de-ramas)).
2. Cambiá el **módulo**. El stack solo se toca si hay variable nueva que el workflow deba pasar.
3. Toda variable nueva:
   - se declara en el módulo **y** en el stack;
   - se pasa en `stacks/.../main.tf`;
   - se documenta cómo llega (`TF_VAR_*` desde GHA).
4. **No cambies la key de `for_each`** de recursos ya aplicados (`filename` sin `.yaml` en Connect). Cambiarla = destroy + create y pérdida de offsets.
5. **No cambies la address** del resource (`confluent_connector.connectors`) sin bloques `moved`. Extraer a otro módulo sin `moved` recrea todo en Confluent.
6. Guards (`terraform_data` + `precondition`): si el `for_each` puede quedar vacío y eso destruiría producción, el plan debe fallar salvo un flag explícito (`allow_empty_connectors`, etc.). Ese flag lo setea el **workflow** (`TF_VAR_...`), no el YAML de app.
7. RBAC: no tragues `resource_type` desconocidos en silencio. Un typo no debe aplicar “a medias”.
8. Provider y `required_version`: el **pin** vive en el stack. El módulo declara el mínimo. No uses solo `>=` suelto en el root cuando este repo ya esté en producción.

### 2.3 Implementar un esqueleto (Flink, SMT, Tableflow, …)

Hoy varios `modules/` y `stacks/` solo tienen README. Para “llenarlos”:

1. Copiá el patrón de `modules/ccloud-connectors` + `stacks/kafka-connect`.
2. El YAML se lee del clone `./externo` vía `TF_VAR_*_dir`, no se copia al repo.
3. Binarios (SMT/UDF): el módulo recibe `artifact_file`; el workflow descarga el JAR. Este repo no versiona el binario.
4. Flink statements **no** suben UDF ni crean connections: consumen ids de `flink-artifacts` / `flink-connections`.
5. Connect **no** sube SMT: consume `transforms.*.custom.smt.artifact.id` del YAML; el upload es `stacks/connect-plugins`.
6. Service accounts del use-case: `eda-core`, no un stack `identity`.
7. Actualizá [STACKS.md](STACKS.md) y [STATE.md](STATE.md) en el mismo PR (key de blob **nueva**, nunca reutilizar `tf-connect.tfstate` ni el de Flink).
8. Avisá al automatizador: hace falta **otro** workflow (o job) con otro `-chdir` y otro `-backend-config key=...`.

### 2.4 Agregar un stack nuevo

Checklist:

- [ ] Módulo sin `provider` / `backend`
- [ ] Stack con backend parcial (`key` la pasa GHA)
- [ ] Variables de Cloud API key solo en el stack
- [ ] Key de state propuesta en `docs/STATE.md` y **distinta** de las existentes
- [ ] Unidad de deploy clara (use-case vs CODAPP vs environment)
- [ ] Dependencia de orden documentada (ej. `eda-core` antes que Connect)
- [ ] `README` del stack con el `-chdir` exacto
- [ ] No hace `terraform apply` de otro stack

### 2.5 Corte desde `flink-v1` (Connect ya aplicado)

Las addresses cambian:

```text
confluent_connector.connectors["…"]
  → module.connectors.confluent_connector.connectors["…"]
```

Sin `moved` (o `state mv`) el primer apply **recrea** conectores. En el PR de corte:

- Plan contra el **mismo** blob `tf-connect.tfstate`.
- Exigir **0 destroy** de `confluent_connector` / `confluent_role_binding` salvo que el ticket lo pida.
- El automatizador apunta `IAC_REF` a esa versión **después** de ver ese plan en DES.

### 2.6 Convenciones de código

- `for_each` por nombre estable (archivo YAML), nunca por índice de lista.
- `terraform fmt` en todo `.tf` del PR.
- Comentarios solo para reglas operativas (ForceNew, destroy masivo, CRN), no para narrar el HCL.
- Secretos: `sensitive = true` en variables; merge Vault → `config_sensitive`; nunca hardcode.
- Un `resource` de Confluent que ya existe en otro stack no se duplica (topics en `eda-core`, no en Connect).

---

## 3. Pruebas que tenés que hacer

No hay aún job de CI en este repo. Las pruebas son **locales + un plan en DES**. Un PR no está listo solo porque “compila en la cabeza”.

### 3.1 Obligatorias en cada PR de Terraform (laptop)

Desde la raíz de este repo:

```bash
# 1. Formato (el CI futuro usará fmt -check; hoy es make fmt)
make fmt
git diff --exit-code   # no dejes fmt sin commitear

# 2. El stack implementado parsea y valida sin backend Azure
make validate-connect
```

`validate-connect` hace `terraform init -backend=false` + `terraform validate` en `stacks/kafka-connect`. No habla con Confluent. Atrapa HCL roto, providers mal declarados, tipos.

Si tocaste **otro** stack con `.tf`, repetí el equivalente:

```bash
cd stacks/<stack>
terraform init -backend=false -input=false
terraform validate
terraform fmt -check
```

Opcional: `pre-commit install` y `pre-commit run --all-files` (ver `.pre-commit-config.yaml`). No sustituye los dos comandos de arriba.

### 3.2 Plan real (cuando el cambio afecta Connect u otro stack ya desplegado)

Necesitás: clone del repo de **resources**, credenciales Cloud API (las de plataforma, no las del conector), y si vas a `init` con backend, acceso al storage del state.

```bash
export EXTERNO=/path/to/PEVE-kafka-connect-resources-v1   # o el repo que usen
export CODAPP=PEVE
export USE_CASE=<carpeta real del use-case>
export ENV_FOLDER=desa

# tf.sh setea TF_VAR_connectors_dir y TF_VAR_security_dir
make plan-connect
```

Hoy `scripts/local/tf.sh` **no** inyecta `environment_id`, `kafka_cluster_id`, API keys ni `-backend-config`. Sin eso el plan no es el de GHA. Completá con env `TF_VAR_*` igual que el workflow, o ejecutá el workflow en DES con `IAC_REF` = tu rama (preferido).

**El plan debe cumplir:**

| Si el PR… | El plan debe… |
|---|---|
| Solo cambia un guard / validación | 0 destroy, 0 replace de conectores |
| Agrega variable con default | 0 replace |
| Cambia `for_each` key o `name` del connector | Mostrar replace; **no mergear** sin ticket que acepte pérdida de offsets |
| Extrae módulo / cambia address | 0 destroy gracias a `moved`, o el PR está incompleto |
| Vacía el contrato de YAML | Fallar por guard, no listar 10 destroys |

Leé el plan: `replace` en `confluent_connector` = recreate. `-/+` en `confluent_role_binding` = corte de ACL a mitad de apply.

### 3.3 Prueba en DES (automatizador + developer)

1. Merge a `main` **o** (mejor para el primer corte) workflow con `IAC_REF=<rama o SHA>`.
2. `plan` del use-case de prueba (no un use-case de negocio crítico).
3. Si el plan es el esperado: `apply` en DES.
4. Verificá en Confluent: conector `RUNNING` o el status del YAML; bindings de topic/subject/group.
5. **No** subas `IAC_REF` de cert/prod hasta tener DES estable y tag (ver ramas).

Pause/resume: el override es in-place; el **siguiente apply** vuelve al `status` del YAML. No lo uses como prueba de un cambio de módulo.

### 3.4 Qué no alcanza como prueba

- Solo `terraform fmt`
- Un apply a un use-case vacío “para ver si init funciona”
- Cambiar YAML en resources y dar por probado el módulo
- CERT/PROD como primer entorno

### 3.5 Cuando exista CI en este repo (objetivo)

El job debería ser, en cada PR:

1. `terraform fmt -recursive -check`
2. `terraform init -backend=false && validate` por cada stack con `.tf`
3. (Opcional) `pre-commit run --all-files`

Eso **no** reemplaza el plan en DES. El apply sigue en el repo de workflows.

---

## 4. Cómo encaja el trabajo con los otros dos repos

```text
PR 1  este repo          → código Terraform
PR 2  resources          → YAML (si el módulo exige un campo nuevo)
PR 3  workflows          → IAC_REF, TF_VAR nuevos, -chdir, backend key
```

Orden:

1. Merge (o tag) de este repo.
2. Workflow: `IAC_REF` apunta a ese tag/SHA.
3. Resources: YAML compatible (el apply lee `./externo`).

Si el módulo es backward compatible (default en variables), resources puede ir **después**. Si el YAML nuevo es obligatorio, el mismo release: tag + YAML + `IAC_REF`.

El developer no “despliega”: el automatizador corre el workflow. El developer entrega un tag/SHA cuyo `plan` ya vio.

---

## 5. Ciclo de vida de ramas

Promoción de **entorno** ≠ promoción de **rama**.  
Promoción de entorno = otro workflow / otra carpeta `desa|cert|prod` en resources + otra key de state.  
Promoción de código = **tag** que el workflow pone en `IAC_REF`.

### 5.1 Ramas de este repo

| Rama / ref | Para qué | Protegida |
|---|---|---|
| `main` | Única rama larga. Código listo para taguear. | Sí: PR + `fmt`/`validate` cuando exista CI |
| `feature/PEVE-<id>-<tema>` | Trabajo de un ticket. Sale de `main`. | No |
| `fix/PEVE-<id>-<tema>` | Bug en código ya tagueado; sale de `main` (o de `release/x.y` si hay parche de versión vieja) | No |
| `release/vX.Y` | Solo si hay que parchear una minor que cert/prod aún pinnean, y `main` ya avanzó | Sí, opcional |

No crear `desa`, `cert`, `prod`, `develop` ni `automation-v3-flink` **en este repo**. Esas ramas viven en workflows/resources, no aquí.

Nombres de feature: `feature/PEVE-5321-connect-group-rbac` (ticket + tema corto). Un PR = un tema. No mezclar “migrar Flink” con “cambiar guard de Connect”.

### 5.2 Flujo (trunk + tags)

```text
main ────────────────────────────────────────────►
   \                      \         tag v1.2.0
    feature/PEVE-… ─PR─►   \
                            fix/PEVE-… ─PR─►
```

1. `git checkout main && git pull`
2. `git checkout -b feature/PEVE-xxxx-corto`
3. Implementar + pruebas [§3](#3-pruebas-que-tenés-que-hacer)
4. PR → `main`. Review de alguien que entienda state (destroy/replace).
5. Merge (squash o merge commit; lo importante es que `main` quede lineal y revertible).
6. El automatizador **no** apunta cert/prod a `main` flotante.
7. Tag semver sobre el commit de `main`:

```bash
git checkout main
git pull
git tag -a v1.2.0 -m "kafka-connect: guard security vacío"
git push origin v1.2.0
```

8. Repo de workflows: `IAC_REF: v1.2.0` (DES primero; cert/prod cuando DES lleve N días o un apply de prueba OK).

### 5.3 Semver para este IaC

| Versión | Cuándo |
|---|---|
| **MAJOR** (`v2.0.0`) | Replace/destroy inevitable, cambio de address sin `moved`, cambio de key de state, variables sin default que rompen el workflow |
| **MINOR** (`v1.2.0`) | Recurso nuevo opt-in, stack nuevo, variable con default |
| **PATCH** (`v1.2.1`) | Guard, mensaje de error, docs, script de validate |

`IAC_REF` en producción: **solo tags**, nunca `main` ni una `feature/*`.

DES puede usar temporalmente `IAC_REF: feature/PEVE-xxxx-...` para el plan/apply de prueba. Cuando cierre el ticket, tag + pin; borrar la rama remota.

### 5.4 Hotfix

1. Rama `fix/PEVE-xxxx-...` desde `main` (o desde `v1.2.0` si cert sigue en esa minor y `main` ya es `v1.3.0-pre`).
2. PR, pruebas, merge a `main`.
3. Tag `v1.2.1` (o `v1.3.1` según corresponda).
4. Workflows: bump de `IAC_REF` en DES → cert → prod. No “hotfix directo a prod” sin el mismo binario tagueado.

Si hay `release/v1.2`: cherry-pick del fix, tag `v1.2.1` desde esa rama, y merge de vuelta a `main` para no perder el parche.

### 5.5 Qué hace cada repo en el mismo cambio

Ejemplo: hay que exigir RBAC `group` y un campo nuevo en el YAML.

| Repo | Rama | Acción |
|---|---|---|
| **automation** (este) | `feature/PEVE-xxxx-group-rbac` → `main` → tag `v1.3.0` | Módulo + guard |
| **resources** | rama de la app / `develop` según su modelo | YAML `security/` con `resource_type: group` |
| **workflows** | la rama desde la que **corren** los Actions (hoy suele ser `automation-v3-flink`) | `IAC_REF: v1.3.0` + `TF_VAR` si aplica |

El automatizador cambia `IAC_REF` en un PR del repo de workflows, no “a mano en el runner”. DES valida el tag; cert/prod bump en PRs separados o el mismo PR con review de plataforma.

### 5.6 Protecciones recomendadas (`main`)

- Nada de push directo.
- PR obligatorio.
- Status check: `fmt -check` + `validate` cuando exista GHA **en este repo**.
- CODEOWNERS del directorio `modules/` y `stacks/`.
- Tags: quien libera es plataforma/automatizador, no cada developer.

---

## 6. Checklist rápido antes de pedir review

- [ ] No hay workflows ni YAML de app en el diff
- [ ] Módulo sin `provider`/`backend`; stack con ambos
- [ ] `make fmt` + `make validate-connect` (o validate del stack tocado)
- [ ] Pensé el `for_each` y las addresses (¿habrá replace?)
- [ ] Variable nueva: módulo + stack + nota para `TF_VAR_` / `IAC_REF`
- [ ] `docs/STACKS.md` / `STATE.md` actualizados si hay stack o key nueva
- [ ] Plan en DES 0-destroy salvo que el ticket lo autorice
- [ ] Rama `feature/PEVE-…` o `fix/PEVE-…`; no commitear a `main`
- [ ] Tras merge: coordinar **tag** + bump de `IAC_REF` (no dejar cert en `main`)

---

## 7. Referencias

- Layout y consumo: [../README.md](../README.md)
- Tres repos: [README.md](README.md)
- Stacks: [STACKS.md](STACKS.md)
- State: [STATE.md](STATE.md)
- Red Connect: [NETWORKING.md](NETWORKING.md)
