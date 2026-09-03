# Tests

Hay una carpeta por stack que ya tiene contrato YAML. Son fixtures, no se aplican.

```
tests/kafka-connect/
tests/flink-compute-pool/
tests/flink-statements/
```

```bash
make test    # fixtures + schema Connect + terraform validate
make lint    # fmt -check + schema sobre fixtures
```

Para lintar un use-case real: `./scripts/ci/schema-lint.sh <connects> <security>`.
