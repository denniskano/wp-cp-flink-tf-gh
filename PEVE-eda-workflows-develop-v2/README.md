# PEVE-Integration

Workflows de GitHub Actions. Temporal Cloud: `deploy-temporal-dev|cert|prod`.

YAML: `PEVE-orchestration-resources` `{CODAPP}/{dev|cert|prod}/`.
IAC: `PEVE-orchestration-automation`.

Prod exige 2 regiones y un par HA que Temporal soporte hoy (el YAML elige; el CI valida `temporal-ha-pairs.json`). `azure-centralus` no tiene réplica Azure–Azure.


