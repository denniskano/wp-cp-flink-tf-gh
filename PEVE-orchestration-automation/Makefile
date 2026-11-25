.DEFAULT_GOAL := help

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: help test lint fmt validate-temporal

help:
	@echo "  make test"
	@echo "  make lint"
	@echo "  make validate-temporal   (terraform validate, sin API)"

test:
	"$(REPO_ROOT)/tests/temporal-cloud/run.sh"

fmt:
	terraform fmt -recursive "$(REPO_ROOT)/modules" "$(REPO_ROOT)/stacks"

lint:
	terraform fmt -check -recursive "$(REPO_ROOT)/modules" "$(REPO_ROOT)/stacks"

validate-temporal:
	cd "$(REPO_ROOT)/stacks/temporal-cloud" && \
	  terraform init -backend=false -input=false && \
	  TF_VAR_temporal_cloud_api_key=dummy TF_VAR_namespaces_dir=/tmp terraform validate
