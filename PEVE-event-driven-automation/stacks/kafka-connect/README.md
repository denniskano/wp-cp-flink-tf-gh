# kafka-connect

Wrapper de `modules/ccloud-connectors`. Un state por use-case.

```
terraform -chdir=stacks/kafka-connect
# o, en GHA: -chdir=iac/stacks/kafka-connect
```

Si el YAML usa SMT custom, el artifact tiene que existir antes (cuando exista `connect-plugins`).
