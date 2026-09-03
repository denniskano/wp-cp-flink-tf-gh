.PHONY: test test-yaml

# Pruebas de este repo (sin Confluent ni Azure). El plan real sigue en DES.
test: test-yaml validate-connect validate-flink-pools validate-flink-stmts

test-yaml:
	"$(REPO_ROOT)/tests/kafka-connect/run.sh"
	"$(REPO_ROOT)/tests/flink-compute-pool/run.sh"
	"$(REPO_ROOT)/tests/flink-statements/run.sh"
