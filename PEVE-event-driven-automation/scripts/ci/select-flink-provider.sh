#!/usr/bin/env bash
# Un solo terraform {} en stacks/flink-statements.
# Uso (cwd = stacks/flink-statements):
#   select-flink-provider.sh a   # DML / apply con backend
#   select-flink-provider.sh b   # DDL sin backend
set -euo pipefail

WHICH="${1:?a|b}"
case "${WHICH}" in
  a|b) ;;
  *) echo "❌ uso: $0 a|b" >&2; exit 1 ;;
esac

if [[ ! -f "provider-${WHICH}.tf.tpl" ]]; then
  echo "❌ no existe provider-${WHICH}.tf.tpl (cwd=$(pwd))" >&2
  exit 1
fi

rm -f provider.tf
cp "provider-${WHICH}.tf.tpl" providers.tf
echo "OK providers.tf ← provider-${WHICH}.tf.tpl (sin provider.tf)"
