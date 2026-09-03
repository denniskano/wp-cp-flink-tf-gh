# Variables compartidas. Entornos (desa|cert|prod) NO viven aquí:
# son carpetas en el repo de resources + key de tfstate.
REPO_ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))

STACK      ?= kafka-connect
CODAPP     ?= PEVE
ENV_FOLDER ?= desa
