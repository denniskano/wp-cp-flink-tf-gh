#!/bin/bash
set -euo pipefail

#Nos ubicamos en el path que contiene el repo base previamente descargado
#tree
cd ./${WORKING_DIR_RESOURCE_PRE_MERGE}
#Branch actual y ultimo commit
echo "$(git branch --show-current)  $(git log -1)"

git fetch origin refs/pull/${NUM_PR}/merge:pr-${NUM_PR}-merge
git branch

if git ls-remote origin refs/pull/${NUM_PR}/merge | grep -q '' ; then
  echo "El PR es mergeable."
else
  echo "❌ El PR NO es mergeable (no existe merge simulado)." >&2
  exit 1
fi

git config --global user.name "CI Merge Bot"
git config --global user.email "ci-merge-bot@example.com"

# Intentar merge sin commit
if git merge --no-commit --no-ff "pr-${NUM_PR}-merge"; then
  echo "Merge aplicado (sin commit) — verificando conflictos..."
else
  echo "❌ git merge retornó error." >&2
  exit 1
fi

# Detectar archivos en conflicto
if git diff --name-only --diff-filter=U | grep -q .; then
  echo "❌ Conflictos detectados:"
  git diff --name-only --diff-filter=U
  # Abortar merge
  git merge --abort || true
  exit 1
else
  echo "✅ Sin conflictos."
fi

