# Pares HA de Temporal Cloud

Temporal admite **1 o 2 regiones** por namespace. **No se pueden cambiar** después de crear. Prod en este IAC **exige 2 regiones** y que el par exista en `scripts/ci/temporal-ha-pairs.json` (copiado de la [tabla oficial](https://docs.temporal.io/evaluate/cloud/regions)).

El YAML elige el par (opción D). El CI valida contra lo que Temporal soporta hoy y falla si prod no es un par válido.

## Lo que Temporal soporta hoy (resumen)

| Primaria | ¿Réplica same-cloud? | ¿Réplica Azure–Azure? | Réplicas HA |
|---|---|---|---|
| `azure-centralus` | No | **No** | Solo **multi-cloud**: `aws-us-east-1`, `aws-us-east-2`, `aws-us-west-2`, `aws-ca-central-1`, `gcp-us-central1`, `gcp-us-west1`, `gcp-us-east4` |
| `azure-australiaeast` | No | No | `aws-ap-southeast-2` |
| `aws-us-east-1` | Same-region replication (cuenta Temporal) | — | `aws-us-east-2`, `aws-us-west-2`, `aws-ca-central-1`, más Azure/GCP US |
| `aws-sa-east-1` | No | — | **Ninguna** (no sirve para prod HA) |
| `gcp-us-central1` | No | — | `gcp-us-west1`, `gcp-us-east4`, más AWS/Azure US |

Azure en Temporal Cloud está en **Public Preview con acceso por ticket**. El alias de Private Link Azure lo da Temporal Dev Success; no sale por API.

## Ejemplos de YAML prod

Si el primario es `azure-centralus` (DES de PEVE):

```yaml
regions:
  - azure-centralus
  - aws-us-east-1   # único tipo de HA disponible desde centralus
```

Same-cloud AWS:

```yaml
regions:
  - aws-us-east-1
  - aws-us-east-2
```

Same-cloud GCP:

```yaml
regions:
  - gcp-us-central1
  - gcp-us-east4
```

HA **privado** en prod: un Connectivity Rule / PE **por cada región** del par. Cloud Governance crea los PE; el YAML solo pone los IDs.

Cuando Temporal publique un par Azure–Azure, se actualiza `temporal-ha-pairs.json` y este doc.
