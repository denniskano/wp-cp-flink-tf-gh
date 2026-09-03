# Tests

Hay una carpeta por stack que ya tiene contrato YAML. Son fixtures, no se aplican.

```
tests/kafka-connect/
tests/flink-compute-pool/
tests/flink-statements/
```

```bash
make test    # fixtures de existencia + terraform validate
make lint    # terraform fmt -check
```

La forma del YAML Connect se lintea en PEVE-kafka-connect-resources-v1.
