# Flink v2 — documentación para aplicaciones

Objetivo de esta carpeta: que un equipo de aplicación pueda **hacer fork** de `PEVE-stream-processing-resources-v1`, **crear su carpeta `{CODAPP}/`** y desplegar **compute pools** y **statements** con el pipeline de `PEVE-event-driven-resources-v2`.

Empieza por el modelo operativo. Los otros dos archivos son el detalle técnico de pools y de SQL.

| Documento | Para qué |
|---|---|
| [MODELO_OPERATIVO.md](MODELO_OPERATIVO.md) | Contrato de directorios, YAML, fork, checklist y cómo lanzar los workflows |
| [FLINK_COMPUTE_POOLS.md](FLINK_COMPUTE_POOLS.md) | Qué es un compute pool, CFU, Autopilot, nombres y lifecycle |
| [FLINK_STATEMENTS.md](FLINK_STATEMENTS.md) | DDL/DML, campos YAML, inmutabilidad del SQL y prácticas |

| Repositorio | Rol de la aplicación |
|---|---|
| `PEVE-stream-processing-resources-v1` | Aquí vive tu carpeta. Solo YAML. |
| `PEVE-event-driven-resources-v2` | No lo forks para tu caso: Terraform y GitHub Actions de plataforma. |
