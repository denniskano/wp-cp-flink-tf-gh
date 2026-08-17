# Fixes pendientes — Flink (compute pools + statements)

Documento de seguimiento para revisión posterior. Generado a partir de la auditoría del módulo Terraform y workflows de GitHub Actions.

**Última actualización:** 2026-05-20

---

## Ya aplicado

| Item | Descripción |
|------|-------------|
| ✅ | Eliminado `.github/workflows/deploy-all.yml` (no funcionaba como reusable workflow) |
| ✅ | Eliminado `terraform/ccloud-flink-statements/moved_count_to_for_each.tf` del raíz (era PEVE; contaminaba otros CODAPP) |
| ✅ | Limpieza repo: `ccloud-flink-statements.bk/`, `main.bk`, `outputs.bk`, `deploy-connectors.bk.yml`, `deploy-flink-statements-test.yml` |
| ✅ | `.gitignore`: patrones `*.bk` y `**/*.bk/` |

---

## Crítico

### 1. Separar claves de backend (Azure Blob)

**Problema:** Varios módulos Terraform comparten o no alinean la misma key de state.

| Módulo | Workflow | Key actual (referencia) |
|--------|----------|-------------------------|
| Compute pools | `deploy-compute-pools.yml` | `dev/${CODAPP}/tf-flink.tfstate` |
| Connectors | `deploy-connectors.yml` | `dev/${CODAPP}/tf-flink.tfstate` |
| Statements | `deploy-flink-statements.yml` | `terraform init` **sin** `-backend-config` |

**Riesgo:** El último `init/apply` de un módulo puede **sobrescribir** el state de otro. Statements en CI puede no usar el mismo state que en local.

**Fix propuesto:**

- `dev/${CODAPP}/tf-flink-cp.tfstate` → compute pools
- `dev/${CODAPP}/tf-flink-stm.tfstate` → statements
- `dev/${CODAPP}/tf-connect.tfstate` → connectors (ya usado en variantes `.bk`)

---

### 2. Workflow statements: `terraform init` con backend

**Archivo:** `.github/workflows/deploy-flink-statements.yml`

Alinear con `deploy-compute-pools.yml` (mismo `storage_account_name`, `container_name`, `ARM_ACCESS_KEY`) pero con key **`tf-flink-stm.tfstate`** (ver punto 1).

---

### 3. Workflow statements: variable `sa_name`

**Problema:** El módulo usa `var.sa_name` + `data.confluent_service_account.sa_princial`. El workflow pasa `TF_VAR_principal_id`, que **no existe** en `variables.tf`.

**Fix propuesto:** Igual que connectors:

```yaml
TF_VAR_sa_name: ${{ env.SERVICE_ACCOUNT }}
```

Eliminar `TF_VAR_principal_id` y la lectura de `PRINCIPAL_ID` en Vault si no se usa.

---

### 4. DNS antes del `terraform plan` (statements)

**Problema:** Orden actual: Init → **Plan** → Configure DNS → Apply.

Con `FLINK_PRIVATE_REST_ENDPOINT` privado, el **refresh** del plan puede fallar o ser inconsistente sin DNS temporal.

**Fix propuesto:** Mover el step *Configure DNS for Confluent Flink* **antes** de *Terraform Plan* (y mantenerlo antes de Apply/Destroy).

---

### 5. Service Account y Vault por CODAPP

**Problema:** En workflows, `SERVICE_ACCOUNT`, rutas Vault y API keys están fijados a **PEVE** para cualquier `CODAPP` (p. ej. BADI).

**Fix propuesto:** Parametrizar por CODAPP (vars de repo, `dev-vars.yaml`, o convención de nombres en Vault).

---

## Alto

### 6. `stopped` con `tobool()` en Terraform

**Archivo:** `terraform/ccloud-flink-statements/main.tf`

```hcl
stopped = try(tobool(each.value["stopped"]), false)
```

Muchos YAML usan `stopped: "false"` / `"true"` (string). El provider espera `bool`.

**Doc:** Regla — booleano sin comillas; en DDL omitir `stopped` salvo pausa operativa.

---

### 7. Fuente de YAML en CI (repo externo)

**Problema:** `deploy-flink-statements.yml` y `deploy-compute-pools.yml` hacen checkout de `denniskano/test-event-driven-resources@develop` y mueven `resources/${CODAPP}`.

Los cambios solo en `wp-cp-flink-tf-gh` **no** entran al plan de Actions hasta publicarlos en el repo externo.

**Opciones:**

- A) Seguir con repo externo y documentar el flujo de publicación.
- B) Usar solo el checkout del repo principal para YAML.

---

### 8. Extensiones de archivo: solo `*.yaml`

**Archivo:** `main.tf` — `fileset(..., "*.yaml")`

Los archivos `.yml` **no** se cargan (caso real en BADI).

**Opciones:** Renombrar a `.yaml` en todos los CODAPP o ampliar `fileset` / validación en CI.

---

### 9. BADI: nombres de compute pool inconsistentes

| Archivos | `flink-compute-pool` |
|----------|----------------------|
| `01`, `02` | `CP_AZC_DES_BADI_01` (fijo DES) |
| `03`–`05`, DML | `CP_AZC_${environment}_BADI_01` |

En CER/PRO los `01`/`02` seguirían apuntando a DES.

**Fix:** Unificar todo a `CP_AZC_${environment}_BADI_01` (o literal por entorno de forma explícita).

---

### 10. Connectors y compute pools: misma key de state

Además del punto 1: **connectors** y **compute pools** no deben compartir `tf-flink.tfstate`.

---

## Medio / operativo

### 11. Orden de ejecución DDL → DML

`depends_on = [confluent_flink_statement.ddl_statements]` hace que **todos** los DML dependan de **todos** los DDL.

PEVE usa hacks `00_fix-order.yaml` / `99_fix-order.yaml` — frágil.

**Fix futuro:** Dependencias explícitas por statement o grafo en YAML.

---

### 12. `data.confluent_flink_region` con varios pools

```hcl
cloud = data.confluent_flink_compute_pool.by_name[keys(...)[0]].cloud
```

Si hubiera pools en clouds distintos, el `cloud` del data source sería incorrecto.

---

### 13. Compute pools: solo `dev-vars.yaml` en CI

El workflow siempre usa `ccloud-flink-compute-pool/dev-vars.yaml`. No hay selector cert/prod en el workflow (la doc describe varios entornos).

---

### 14. Validación en CI o precondiciones Terraform

- `statement-name` único por CODAPP
- Extensión `.yaml` / no `.yml`
- `stopped` booleano (no string)
- YAML válido antes de `plan`

La doc menciona `lifecycle.precondition` para `statement-name`; **no está** en `main.tf` actual.

---

### 15. Documentación operativa (runbooks)

Temas a documentar en `FLINK_STATEMENTS.md` / `FLINK_COMPUTE_POOLS.md`:

- Statement DDL en `COMPLETED` borrado en Confluent → Terraform lo recrea en el siguiente apply
- No borrar statements gestionados por TF en UI/CLI
- SQL del statement es inmutable → replace / nuevo `statement-name`
- Retención ~30 días en estados terminales (STOPPED)
- `tainted` en state → replace forzado; `terraform untaint` si no era intencional

---

### 16. Variables y estilo en módulo statements

- `sa_name` marcado `sensitive = true` sin ser secreto
- Typo `sa_princial` en locals
- Locals de credenciales duplicados sin uso en recursos

---

### 17. Versión del provider Confluent

`provider.tf`: `version = ">= 2.7.0"` muy abierto.

**Fix:** Fijar versión probada en `.terraform.lock.hcl` y en CI.

---

### 18. YAML BADI: quitar `stopped` en DDL

Solo `04` y `05` tienen `stopped: "false"` redundante. Omitir en DDL (default `false`).

---

## Bajo / deuda técnica

| # | Item |
|---|------|
| 19 | `CATALOG_NAME` / `CLUSTER_NAME` hardcodeados en workflow (valores PEVE/demo) |
| 20 | Revisar si `PEVE/.../dml/00_fix-order.yaml` y `99_fix-order.yaml` siguen siendo necesarios tras `for_each` |
| 21 | Doc PFMT / `migrations-pfmt` menciona `ddl_statements_frozen` — no existe en `main.tf` actual |
| 22 | Step “Configure Azure Storage Access” en compute pools: `export` en subshell sin efecto |
| 23 | Terraform 1.5.0 fijo en CI; valorar 1.6+ alineado con entorno local |
| 24 | `GITHUB_TOKEN` para checkout cross-repo: verificar permisos org/repo externo |

---

## Orden sugerido de implementación

1. Backend keys (cp / stm / connect) + `init` en statements  
2. `TF_VAR_sa_name`, quitar `principal_id`, DNS antes del plan  
3. `tobool(stopped)` + reglas en documentación  
4. BADI pools + convención `.yaml`  
5. SA/Vault por CODAPP  
6. Decisión monorepo vs `test-event-driven-resources`  

---

## Referencias en repo

| Área | Rutas |
|------|--------|
| Módulo statements | `terraform/ccloud-flink-statements/` |
| Módulo compute pools | `terraform/ccloud-flink-compute-pool/` |
| Migraciones count→for_each | `terraform/ccloud-flink-statements/migrations-{badi,peve,pfmt}/` |
| Workflows | `.github/workflows/deploy-flink-statements.yml`, `deploy-compute-pools.yml`, `deploy-connectors.yml` |
| Docs | `docs/FLINK_STATEMENTS.md`, `docs/FLINK_COMPUTE_POOLS.md` |

---

## Notas de contexto (incidentes ya entendidos)

- Archivos `.yml` no aparecían en plan → usar `.yaml`
- DDLs se re-ejecutaban porque el statement se **borraba en Confluent** → drift + recreate
- `outputs` (`ddl_statements`, `all_statements`) listan solo recursos en **state**, no YAML del disco
- Migración a `for_each` hecha por CODAPP con `moved` en `migrations-*/`; no dejar `moved` de otro CODAPP en el raíz del módulo
