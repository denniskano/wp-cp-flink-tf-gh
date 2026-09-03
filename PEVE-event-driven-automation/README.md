# PEVE-event-driven-automation

Infraestructura como código (Terraform) para Confluent Cloud: Kafka Connect (incl. SMT), Flink (pools, artifacts, connections, statements), EDA, Tableflow, ksql y Private Link de egress.

Este repositorio **no** contiene:

- GitHub Actions (`PEVE-event-driven-resources-v2`)
- YAML de aplicación (va en PEVE-kafka-connect-resources-v1, PEVE-stream-processing-resources-v2 o PEVE-event-driven-resources-v3)

El workflow clona este repo (`IAC_REF`) y el de YAML (`./externo`), y ejecuta un **stack**. Mapa de los cinco repos: [docs/README.md](docs/README.md).

## Layout

```
modules/     # reutilizables; sin backend ni provider
stacks/      # raíces ejecutables; backend Azure RM + provider
scripts/     # ci (GHA) y local
tests/       # fixtures por stack (no YAML de app, no entornos)
make/        # lint, test, stacks — no domains create/delete
schemas/     # JSON Schema connects/ + security/ (repo de resources)
docs/        # contrato entre los cinco repos
```

Un stack = un tfstate = un workflow. Implementados: `kafka-connect`, `flink-compute-pool`, `flink-statements`. El resto son esqueletos. Mapa en [docs/STACKS.md](docs/STACKS.md).

## Consumo desde PEVE-event-driven-resources-v2

```text
checkout PEVE-event-driven-automation@IAC_REF           →  ./iac
checkout PEVE-kafka-connect-resources-v1@branch         →  ./externo   # stack kafka-connect
# o PEVE-stream-processing-resources-v2                  →  ./externo   # Flink
# o PEVE-event-driven-resources-v3                       →  ./externo   # eda-core
terraform -chdir=./iac/stacks/kafka-connect init|plan|apply
  TF_VAR_connectors_dir=../../externo/{CODAPP}/desa/{use_case}/connects
  TF_VAR_security_dir=../../externo/{CODAPP}/desa/{use_case}/security
```

State (ejemplo DES): `dev/{CODAPP}/{use_case}/tf-connect.tfstate`. Detalle en [docs/STATE.md](docs/STATE.md).

Cómo implementar, probar y versionar: [docs/DEVELOPER.md](docs/DEVELOPER.md). Contrato YAML Connect (JSON Schema): [schemas/README.md](schemas/README.md).

## Local

```bash
make lint
make test
make fmt
make validate-connect
make validate-flink-pools
make validate-flink-stmts
EXTERNO=/path/to/PEVE-kafka-connect-resources-v1 CODAPP=PEVE USE_CASE=use-case-name-02 make plan-connect
EXTERNO=/path/to/PEVE-stream-processing-resources-v2 CODAPP=PEVE make plan-flink-pools
EXTERNO=/path/to/PEVE-stream-processing-resources-v2 CODAPP=PEVE PIPELINE=pipeline-nombre-caso-negocio-compras-04 make plan-flink-stmts
```
