# PEVE-event-driven-automation

Infraestructura como código (Terraform) para Confluent Cloud: Kafka Connect (incl. SMT), Flink (pools, artifacts, connections, statements), EDA, Tableflow, ksql y Private Link de egress.

Este repositorio **no** contiene:

- GitHub Actions (otro repo de workflows)
- YAML de aplicación (`connects/`, statements, topics, … — repo de resources)

El workflow clona este repo (`IAC_REF`) y el de YAML (`./externo`), y ejecuta un **stack**.

## Layout

```
modules/     # reutilizables; sin backend ni provider
stacks/      # raíces ejecutables; backend Azure RM + provider
scripts/     # ci (invocados por GHA) y local (Make)
docs/        # contrato entre los tres repos
```

Un stack = un tfstate = un workflow. `kafka-connect` es el único stack implementado; el resto son esqueletos. Mapa en [docs/STACKS.md](docs/STACKS.md).

## Consumo desde el repo de workflows

```text
checkout PEVE-event-driven-automation@IAC_REF  →  ./iac
checkout {resources}@branch                    →  ./externo
terraform -chdir=./iac/stacks/kafka-connect init|plan|apply
  TF_VAR_connectors_dir=../../externo/{CODAPP}/desa/{use_case}/connects
  TF_VAR_security_dir=../../externo/{CODAPP}/desa/{use_case}/security
```

State (ejemplo DES): `dev/{CODAPP}/{use_case}/tf-connect.tfstate`. Detalle en [docs/STATE.md](docs/STATE.md).

Cómo implementar, probar y versionar: [docs/DEVELOPER.md](docs/DEVELOPER.md).

## Local

```bash
make fmt
make validate-connect
EXTERNO=/path/to/resources CODAPP=PEVE USE_CASE=demo-postgres-01 make plan-connect
```
