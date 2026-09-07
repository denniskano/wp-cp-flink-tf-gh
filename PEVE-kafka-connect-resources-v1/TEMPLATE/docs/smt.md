# Custom SMT (Confluent Cloud)

Guía de **uso**: cómo declarar el JAR, subirlo al environment y referenciarlo en un conector full-managed.

El JAR se construye y publica en Artifactory con el job Jenkins de SMT. Este repo solo declara **de dónde bajarlo** y con qué nombre subirlo. El binario no se versiona aquí.

- Plantilla: [`../smt.yaml`](../smt.yaml)
- Destino: `{CODAPP}/{desa|cert|prod}/smt.yaml` (un archivo por aplicación y ambiente, **no** por use-case)
- Ejemplo: `PEVE/desa/smt.yaml`
- Doc oficial: [Custom SMT for fully-managed connectors](https://docs.confluent.io/cloud/current/connectors/configure-custom-single-message-transforms/quick-start-custom-smt.html)

## Cuándo usarlo

| | SMT nativo (Cast, Mask, HoistField, …) | Custom SMT (JAR propio) |
|---|---|---|
| Dónde se declara | Solo en el YAML del conector | `smt.yaml` + YAML del conector |
| `transforms.<alias>.type` | Clase de Kafka Connect / Confluent | FQCN de tu clase (`…$Value` / `…$Key`) |
| `custom.smt.artifact.id` | No | Sí: el `ca-…` del apply |
| Archivo `smt.yaml` | No lo crees | Obligatorio |

Si no usas JAR propio, no crees `smt.yaml` y no pongas `custom.smt.artifact.id`.

No hay ConfigMap ni `CLASSPATH`. Eso es self-managed.

## Alcance

El artifact (`ca-…`) es del **environment + AZURE**. Cualquier conector de cualquier cluster de ese environment puede usarlo.

- Tope CCloud: 10 artifacts / 100 MB por environment
- `name` único en el environment
- No es por cluster ni por use-case

## `smt.yaml`

```yaml
artifacts:
  - name: peve-kafka-transformer
    url: http://10.79.118.71:8081/artifactory/PEVE-DESA/com/bcp/peve/peve-kafka-transformer/1.0.0/peve-kafka-transformer-1.0.0.jar
    description: "BytesToAvroAuditWithSchemaParser"
    content_format: JAR
```

| Campo | Obligatorio | Para qué |
|---|---|---|
| `artifacts[].name` | sí | `display_name` en Confluent y key de Terraform. **No lo renombres** después del primer apply. |
| `artifacts[].url` | sí | URL de Artifactory (línea `[INFO] Deploying artifact:` del job SMT). |
| `artifacts[].description` | no | Texto en la UI de Artifacts. |
| `artifacts[].content_format` | no | `JAR` (default) o `ZIP`. |

Puedes listar varios artifacts (respetando el tope de 10).

### URL por ambiente

Cada carpeta lleva **su** URL. El workflow no la reescribe.

| Ambiente | Repo Artifactory |
|---|---|
| desa | la que imprima el job develop |
| cert | `…/artifactory/PEVE-CERT/com/bcp/{codapp}/…` |
| prod | la de cert, `PEVE-CERT` → `PEVE.Release` |

## Cómo se usa (primera vez)

CCloud no busca el JAR por el `name`. Después de subirlo le asigna un id (`ca-…`) y **ese** es el que va en el conector. El id no existe hasta el primer apply.

1. Publica el JAR con el job Jenkins de SMT. Copia la URL `[INFO] Deploying artifact:`.
2. Crea `{CODAPP}/desa/smt.yaml` (`name` + `url`). PR + merge a `develop`.
3. Corre **`deploy-connect-plugins`** (`plan`, luego `apply`; input `CODAPP`). El job hace `curl` anónimo (misma red que Jenkins) y sube el artifact.
4. En el log, copia el id:

```text
artifact_ids = {
  "peve-kafka-transformer" = "ca-abc123"
}
```

También aparece en Confluent: Environment → Connectors → Artifacts.

5. Pega el `ca-…` en el YAML del **conector** (`connects/`), no en `smt.yaml`:

```yaml
config_nonsensitive:
  transforms: mySmt
  transforms.mySmt.type: com.bcp.peve.kafka.connect.smt.BytesToAvroAuditWithSchemaParser$Value
  transforms.mySmt.custom.smt.artifact.id: ca-abc123
```

Varios transforms: `transforms: smtA,smtB` y un `custom.smt.artifact.id` por alias que use JAR propio.

6. Recién ahí **`deploy-kafka-connect`**. El artifact tiene que existir **antes**. Si el conector apunta a un `ca-…` que no está, queda Failed.

Hoy el job de plugins apunta a **DES**. cert/prod: misma forma cuando exista el workflow; el `ca-…` es **otro** por environment.

## Ciclo de vida

CCloud no versiona el artifact ni tiene pause/resume (eso es del conector).

| Qué quieres | Qué haces |
|---|---|
| Seguir igual | No toques `name`. El `ca-…` se mantiene; no hay que volver a pegarlo. |
| Nueva versión del JAR | Publica en Artifactory, cambia solo la `url` (mismo `name`), `apply` de plugins. El `ca-…` suele mantenerse. |
| Otro SMT (otra clase / otro JAR) | Otro item en `artifacts` (otro `name`) o reutiliza el mismo JAR si ya está en el environment. |
| Dejar de usar el SMT en un conector | Quita `transforms` / el `ca-…` de ese YAML y aplica el conector. El artifact puede quedarse. |
| Borrar el artifact | Saca el item de `smt.yaml` y `apply` de plugins. **No hay destroy** en el job. Los conectores que sigan con ese `ca-…` quedan Failed. |

### No hagas esto

- Poner el `name` (`peve-kafka-transformer`) en `custom.smt.artifact.id`. Ahí va solo `ca-…`.
- Renombrar `name` después del primer apply: CCloud crea otro artifact, otro id; hay que actualizar todos los conectores.
- Aplicar el conector antes que plugins.
- Inventar el `ca-…`.
- Meter el JAR en este repo.

## En el conector (Event Hubs, típico)

Payload bytes → Avro. Guía del conector: [eventhubs-source.md](eventhubs-source.md).

```yaml
transforms: ToAvroAuditWithSchema
transforms.ToAvroAuditWithSchema.type: com.bcp.peve.kafka.connect.smt.BytesToAvroAuditWithSchemaParser$Value
transforms.ToAvroAuditWithSchema.custom.smt.artifact.id: ca-xxxxx
```
