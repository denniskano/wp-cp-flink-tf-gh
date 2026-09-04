# ccloud-connect-smt

Pendiente. `confluent_connect_artifact` (JAR o ZIP, cloud AZURE).

En el yaml del connector:

```
transforms: mySmt
transforms.mySmt.type: com.example.MyTransform
transforms.mySmt.custom.smt.artifact.id: ca-xxxxx
```

Si borras el artifact y un connector lo sigue usando, el connector queda Failed.
