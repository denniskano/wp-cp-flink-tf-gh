# PEVE-orchestration-resources

YAML de gobernanza Temporal Cloud. Un directorio por aplicación (`CODAPP` de 4 caracteres) y entorno `dev` | `cert` | `prod`.

```
{CODAPP}/
  dev|cert|prod/
    namespaces/*.yaml   # uno o más namespaces (peve-dev, peve-dev-pagos, …)
    nexus/*.yaml        # opcional, mismo env
```

**Campos y valores:** [docs/NAMESPACE.md](docs/NAMESPACE.md) · [docs/NEXUS.md](docs/NEXUS.md).  
**Plantillas:** [TEMPLATE/](TEMPLATE/README.md) (copiar; no se despliega).

El nombre del namespace es `{codapp}-{dev|cert|prod}[-suffix]`.

`labels` (o `tags`) van a Temporal Cloud namespace tags. Minúsculas, máx. 10 pares. Ejemplo: `codapp: peve`, `env: dev`.

Prod: **dos** regiones que sean par HA de Temporal (no hay Azure–Azure desde `azure-centralus`). Detalle: IAC `docs/TEMPORAL-HA.md`.

PrivateLink: **un PE por entorno** (prod: uno por región HA); las connectivity rules van **por namespace** con el mismo ID. [docs/PRIVATELINK.md](docs/PRIVATELINK.md).

GHA: `deploy-temporal-dev|cert|prod` en PEVE-eda-workflows-develop-v2.
