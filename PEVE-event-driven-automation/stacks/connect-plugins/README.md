# connect-plugins

Wrapper de `modules/ccloud-connect-smt`. Un state por **CODAPP** (el artifact es del environment + AZURE, no del use-case).

Lee `{CODAPP}/{desa|cert|prod}/smt.yaml`. El workflow baja cada `artifacts[].url` de Artifactory y pasa `artifact_files` (name → path local).

```
terraform -chdir=stacks/connect-plugins
# o, en GHA: -chdir=iac/stacks/connect-plugins
```

Aplícalo **antes** que `kafka-connect`. El conector no sube el JAR: en el YAML solo va `transforms.*.custom.smt.artifact.id` (`ca-…`).

State DES (key nueva; no reutiliza `tf-connect.tfstate`):

`dev/{CODAPP}/connect-plugins/tf-connect-plugins.tfstate`

Workflow DES: `deploy-connect-plugins` (plan/apply). `curl` anónimo (igual que Jenkins) y aplica este stack.

Uso (YAML, `ca-…`, ciclo de vida): en el repo de resources, `TEMPLATE/docs/smt.md`.

- Crear: item en `smt.yaml` → apply.
- Nueva versión: cambia `url`, mismo `name` → apply.
- Borrar: saca el item → apply (los conectores con ese `ca-…` quedan Failed). No hay `destroy` en el job.
- Renombrar `name` recrea el artifact (otro `ca-…`).
