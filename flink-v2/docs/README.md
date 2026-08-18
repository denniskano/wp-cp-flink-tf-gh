# Flink v2 — documentación para aplicaciones

Objetivo: que un equipo haga **fork** de `PEVE-stream-processing-resources-v1`, cree su carpeta `{CODAPP}/` y, tras el **pull request**, pida el despliegue con **ticket Jira** (el tipo de ticket define desa / cert / prod).

El Service Account de los statements se da de alta **antes**, con **otro ticket Jira** (el proceso crea el SA y lo deja en HashiCorp Vault).

| Documento | Para qué |
|---|---|
| [MODELO_OPERATIVO.md](MODELO_OPERATIVO.md) | Carpetas, YAML, fork, PR, prerrequisito de SA y tickets de despliegue |
| [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md) | Compute pool, CFU, Autopilot y lifecycle |
| [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md) | DDL/DML, campos YAML, inmutabilidad del SQL y prácticas |

El repositorio que versiona el equipo es `PEVE-stream-processing-resources-v1` (solo YAML).
