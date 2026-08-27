# Contrato entre repos

| Repo | Rol |
|---|---|
| **PEVE-event-driven-automation** (este) | Módulos y stacks Terraform, scripts, Makefile |
| **Workflows** | `.github/workflows`, `single-encrypt` / `single-decrypt` |
| **Resources** | YAML `{CODAPP}/{desa\|cert\|prod}/...` |

El workflow **no** vive aquí. En cada run:

1. Checkout de este repo en `./iac` (`IAC_REF` = tag o rama).
2. Checkout de resources en `./externo` (GitHub App).
3. `terraform -chdir=./iac/stacks/<stack>` con `TF_VAR_*_dir` apuntando a `./externo`.

No hay YAML de conectores ni statements en este repositorio. Los JAR/ZIP (UDF Flink, SMT) tampoco: el workflow los baja y pasa `artifact_file`.

Manual de implementación, pruebas y ramas: [DEVELOPER.md](DEVELOPER.md).
