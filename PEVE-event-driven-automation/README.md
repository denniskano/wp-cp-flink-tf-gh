# PEVE-event-driven-automation

Terraform para Confluent Cloud (Connect, Flink, topics/SR/RBAC). Los workflows están en `PEVE-event-driven-resources-v2`. El YAML de cada app va en el repo de resources que corresponda.

En Actions este repo se clona a `./iac` (`IAC_REF`). El YAML se clona a `./externo`.

```
modules/              # lógica compartida; no tienen backend
stacks/               # lo que se aplica (un directorio = un state)
resources/template/   # .tf.tpl para Flink y eda-core
scripts/              # generate_*, gen_*_flink, terraform_task, validate
tests/ make/ docs/
```

Hoy se usa de verdad: `kafka-connect`, `flink-compute-pool`, `flink-statements`, `eda-core`. El resto de `stacks/` está vacío o a medio hacer.

```bash
make lint
make test
make fmt

EXTERNO=/ruta/PEVE-kafka-connect-resources-v1 CODAPP=PEVE USE_CASE=use-case-name-02 make plan-connect
EXTERNO=/ruta/PEVE-stream-processing-resources-v2 CODAPP=PEVE make plan-flink-pools
EXTERNO=/ruta/PEVE-stream-processing-resources-v2 CODAPP=PEVE PIPELINE=pipeline-nombre-caso-negocio-compras-04 make plan-flink-stmts
```

Stacks y keys de state: [docs/STACKS.md](docs/STACKS.md), [docs/STATE.md](docs/STATE.md). Cómo trabajar un PR: [docs/DEVELOPER.md](docs/DEVELOPER.md).
