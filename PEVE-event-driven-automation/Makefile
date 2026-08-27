.PHONY: help fmt validate-connect

STACK ?= kafka-connect

help:
	@echo "PEVE-event-driven-automation — IaC (sin workflows ni YAML de app)"
	@echo ""
	@echo "  make fmt                 terraform fmt -recursive"
	@echo "  make validate-connect    init -backend=false + validate (stack kafka-connect)"
	@echo "  make plan-connect        scripts/local/tf.sh kafka-connect plan"
	@echo ""
	@echo "Variables para scripts/local/tf.sh:"
	@echo "  EXTERNO   path al clone del repo de resources"
	@echo "  CODAPP    (default PEVE)"
	@echo "  USE_CASE  carpeta del use-case"
	@echo "  ENV_FOLDER desa|cert|prod"

fmt:
	terraform fmt -recursive

validate-connect:
	cd stacks/kafka-connect && terraform init -backend=false -input=false && terraform validate

plan-connect:
	./scripts/local/tf.sh kafka-connect plan
