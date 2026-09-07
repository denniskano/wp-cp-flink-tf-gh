# ccloud-connect-smt

Sube Custom SMT a Confluent Cloud (`confluent_connect_artifact`, id `ca-…`). Alcance: **environment + cloud** (AZURE). Tope de CCloud: 10 artifacts / 100 MB.

El `for_each` es `artifacts[].name` de `smt.yaml`. Si lo renombras después del primer apply, se recrea el artifact.

El JAR no vive en este repo. El workflow hace curl a `artifacts[].url` (Artifactory) y pasa `artifact_files`.

En el YAML del conector:

```yaml
transforms: mySmt
transforms.mySmt.type: com.example.MyTransform
transforms.mySmt.custom.smt.artifact.id: ca-xxxxx
```

Si borras el artifact y un conector lo sigue usando, el conector queda Failed.
