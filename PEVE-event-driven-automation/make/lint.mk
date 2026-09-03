.PHONY: fmt fmt-check lint

fmt:
	cd "$(REPO_ROOT)" && terraform fmt -recursive

fmt-check:
	cd "$(REPO_ROOT)" && terraform fmt -recursive -check

lint: fmt-check
