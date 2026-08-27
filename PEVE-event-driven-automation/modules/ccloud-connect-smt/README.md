# ccloud-connect-smt

Esqueleto. Sube un **Custom SMT** (Single Message Transform) para conectores full-managed.

Recurso: `confluent_connect_artifact` (`content_format` `JAR` | `ZIP`, `cloud` = `AZURE`).

El conector (stack `kafka-connect`) no sube el JAR. En `config_nonsensitive` del YAML de resources:

```text
transforms: mySmt
transforms.mySmt.type: com.example.MyTransform
transforms.mySmt.custom.smt.artifact.id: <id del artifact, ca-…>
```

Unidad: plataforma / environment. Borrar el artifact mientras un conector lo usa deja el connector Failed.
