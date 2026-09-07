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

Workflow DES: `deploy-connect-plugins` (plan/apply). Baja el JAR de Artifactory y aplica este stack.
