# kafka-connect

Wrapper de `modules/ccloud-connectors`. Un state por use-case.

```
terraform -chdir=stacks/kafka-connect
# o, en GHA: -chdir=iac/stacks/kafka-connect
```

Si el YAML usa Custom SMT, aplica `connect-plugins` **antes**. El conector no sube el JAR: necesita `transforms.*.custom.smt.artifact.id` con el `ca-…` que imprime ese apply. SMT nativo de Confluent no usa `smt.yaml` ni ese campo.
