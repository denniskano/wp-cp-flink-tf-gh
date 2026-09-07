# Custom SMT (Confluent Cloud)

El JAR se construye y publica en Artifactory con el job Jenkins de SMT. Este repo solo declara **de dónde bajarlo** y con qué nombre subirlo al environment.

- Plantilla: [`../smt.yaml`](../smt.yaml)
- Destino: `{CODAPP}/{desa|cert|prod}/smt.yaml` (un archivo por código de aplicación)
- En el conector: sección **Custom SMT** del [README](../../README.md)
- Doc oficial: [Custom SMT for fully-managed connectors](https://docs.confluent.io/cloud/current/connectors/configure-custom-single-message-transforms/quick-start-custom-smt.html)

## Alcance

El artifact (`ca-…`) es del **environment + AZURE**. Cualquier conector de cualquier cluster de ese environment puede usarlo. Tope: 10 artifacts / 100 MB. `name` es único en el environment.

No hay ConfigMap ni `CLASSPATH`. Eso es self-managed.

## YAML (`smt.yaml`)

| Campo | Obligatorio | Para qué |
|---|---|---|
| `artifacts[].name` | sí | `display_name` en Confluent. Key de Terraform. No lo renombres después del primer apply. |
| `artifacts[].url` | sí | `transformer_url` de Artifactory. |
| `artifacts[].description` | no | Texto en la UI de Artifacts. |
| `artifacts[].content_format` | no | `JAR` (default) o `ZIP`. |

Si la app no usa SMT custom, no crees el archivo.

## URL por ambiente

| Ambiente | Repo Artifactory |
|---|---|
| cert | `…/artifactory/PEVE-CERT/com/bcp/{codapp}/…` (línea `[INFO] Deploying artifact:` del job cert) |
| prod | la de cert, `PEVE-CERT` → `PEVE.Release` |
| desa | la que imprima el job develop (`[INFO] Deploying artifact:`) |

Cada carpeta `desa` / `cert` / `prod` lleva **su** URL. El workflow no la reescribe.

## Por qué el `ca-…` no va en `smt.yaml`

Confluent no identifica el JAR por el `name`. Después de subirlo le asigna un id (`ca-…`) y **ese** es el que el conector declara en `transforms.*.custom.smt.artifact.id`.

El id **no existe** hasta el primer apply del artifact. Por eso el flujo es:

1. `smt.yaml` (`name` + `url`) → job **`deploy-connect-plugins`**.
2. El apply imprime `artifact_ids = { "peve-kafka-transformer" = "ca-abc123" }`.
3. Copias `ca-abc123` al YAML del **conector** (`connects/`).
4. Aplicas el conector. CCloud carga la clase desde ese artifact.

```yaml
config_nonsensitive:
  transforms: mySmt
  transforms.mySmt.type: com.bcp.peve.kafka.connect.smt.BytesToAvroAuditWithSchemaParser$Value
  transforms.mySmt.custom.smt.artifact.id: ca-abc123
```

`name` es solo la etiqueta. No lo pongas en `custom.smt.artifact.id`.

Si no cambias el `name`, el `ca-…` se mantiene. Si lo renombras o lo borras, Confluent crea otro id y el conector queda Failed hasta que actualices el YAML.

El artifact tiene que existir **antes** que el conector. SMT nativo de Confluent (Cast, Mask, etc.) no usa `smt.yaml` ni `custom.smt.artifact.id`.
