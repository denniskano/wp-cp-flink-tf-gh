.PHONY: fmt fmt-check lint lint-yaml

fmt:
	cd "$(REPO_ROOT)" && terraform fmt -recursive

fmt-check:
	cd "$(REPO_ROOT)" && terraform fmt -recursive -check

lint-yaml:
	"$(REPO_ROOT)/scripts/ci/schema-lint.sh" \
		"$(REPO_ROOT)/tests/kafka-connect/fixtures/connects" \
		"$(REPO_ROOT)/tests/kafka-connect/fixtures/security"

lint: fmt-check lint-yaml
