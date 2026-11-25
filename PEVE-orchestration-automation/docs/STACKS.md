# Stacks

| Stack | Cómo se arma | Unidad | YAML | Workflow |
|---|---|---|---|---|
| temporal-cloud | módulo `temporal-cloud` (yamldecode) | CODAPP + env | PEVE-orchestration-resources `{CODAPP}/{dev\|cert\|prod}/` | deploy-temporal-{dev,cert,prod} |

Un apply por CODAPP/env. Varios namespaces en el mismo directorio.

Regiones: 1 (dev/cert) o 2 (prod, par HA válido). No se cambian después de crear.
