#!/bin/bash
set -euo pipefail

#VAR1="$1"

if [[ ! "$CODAPP" =~ ^[A-Z0-9]{4}$ ]]; then
  echo "❌ [$CODAPP] debe tener exactamente 4 caracteres sin espacios en blanco, usando solo letras mayúsculas y/o números."
  exit 1
fi
echo "✅ CODAPP válido: $CODAPP"

if [[ ! "$NUM_PR" =~ ^[0-9]{1,}$ ]]; then
  echo "❌ [$NUM_PR] debe ser solo números."
  exit 1
fi
echo "✅ NUM_PR válido: $NUM_PR"

if [[ ! "$COMMIT_ID" =~ ^[a-z0-9]{8,}$ ]]; then
  echo "❌ [$COMMIT_ID] debe ser mayor a 7 caracteres sin espacios en blanco, usando solo letras minúsculas y/o números."
  exit 1
fi
echo "✅ COMMIT_ID válido: $COMMIT_ID"

