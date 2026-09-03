#!/bin/bash
# Construir el prefijo a buscar basado en inputs del workflow
set -euo pipefail
FindPath="${NAME_DIR_APP}/${AMBIENTE}"
shopt -s extglob   # habilita patrones extendidos
patternAvroValue="$FindPath/asyncapi/*-value-v+([0-9]).avsc"
patternAvroKey="$FindPath/asyncapi/*-key-v+([0-9]).avsc"

MATCHED_FILES=""
NO_MATCHED_FILES=""

PAGE=1

while :; do
  RESP=$(curl -sS -H "Authorization: Bearer ${TOKEN}" \
                -H "Accept: application/vnd.github+json" \
                "https://api.github.com/repos/${OWNER_REPO}/pulls/${NUM_PR}/files?per_page=100&page=${PAGE}")
  COUNT=$(echo "$RESP" | jq 'length')
  if [ "$COUNT" -eq 0 ]; then
    break
  fi
  # Extraer rutas de archivos del PR: una por línea
  BATCH=$(echo "$RESP" | jq -r '.[] | "\(.status)\t\(.filename)"')

  # Iterar línea a línea (sin alterar espacios internos)
  while IFS=$'\t' read -r status f; do
    [[ -z "$f" ]] && continue

	# Ignorar eliminados
	[[ "$status" == "removed" ]] && continue

    # Verificar si el path empieza con el prefijo
    if [[ "$f" == "$FindPath/"* ]]; then

      #Validar path y archivo yaml topics

      if [[ "$f" == "$FindPath/topics/cc-azure_eu2_kafka01-topics.yaml" ]]; then
        MATCHED_FILES+="${f} "
        echo "✅ $f"
      elif [[ "$f" == "$FindPath/security/cc-azure_eu2_kafka01-rbac-$SECURITY_ENV.yaml" ]]; then
        MATCHED_FILES+="${f} "
        echo "✅ $f"
      elif [[ "$f" == "$FindPath/governance/sr-azccdeu2peve02_bcp-subjects.yaml" ]]; then
        MATCHED_FILES+="${f} "
        echo "✅ $f"
      elif [[ "$f" == $patternAvroValue ]]; then
        MATCHED_FILES+="${f} "
        echo "✅ $f"
      elif [[ "$f" == $patternAvroKey ]]; then
        MATCHED_FILES+="${f} "
        echo "✅ $f"
      else
        NO_MATCHED_FILES+="${f} \n"
        echo "❌ not allowed: $f"
      fi

    else
      NO_MATCHED_FILES+="${f} \n"
      echo "❌ not allowed: $f"
    fi
  done <<< "$BATCH"

  PAGE=$((PAGE+1))
done

# Normalizar (quitar espacios extra al final)
#MATCHED_FILES=$(echo "$MATCHED_FILES" | xargs)
#NO_MATCHED_FILES=$(echo "$NO_MATCHED_FILES" | xargs)
#echo "ALL Matches:  $MATCHED_FILES"

if [ -n "$NO_MATCHED_FILES" ]; then
  echo "❌ Cambios no permitidos para $FindPath de los archivos:  $NO_MATCHED_FILES"
  exit 1
fi

#if [ -n "$MATCHED_FILES" ]; then
#  echo "✅ Verified $FindPath Files ==>  $MATCHED_FILES"
#fi

