#!/usr/bin/env bash
# Reconstruye un proyecto a partir de un .txt generado por quarkus-pack.sh
#
# Uso:
#   ./quarkus-unpack.sh DIRECTORIO_DESTINO [ARCHIVO_PACK.txt]
# Si no se indica archivo, lee de stdin:
#   ./quarkus-unpack.sh ./mi-proyecto-reconstruido < proyecto.pack.txt
#
set -euo pipefail

if [[ $# -lt 1 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    sed -n '2,10p' "$0"
    exit 0
fi

DEST_ROOT="$1"
shift
INPUT="${1:-/dev/stdin}"
if [[ -n "${1:-}" ]] && [[ "$INPUT" != /dev/stdin ]]; then
    [[ -r "$INPUT" ]] || { echo "No se puede leer: $INPUT" >&2; exit 1; }
fi

mkdir -p "$DEST_ROOT"
DEST_ROOT="$(cd "$DEST_ROOT" && pwd)"

state=seek_header
current_path=""
tmpfile=""

cleanup() {
    if [[ -n "${tmpfile:-}" ]] && [[ -f "$tmpfile" ]]; then
        rm -f "$tmpfile"
    fi
    return 0
}
trap cleanup EXIT

while IFS= read -r line || [[ -n "$line" ]]; do
    case "$state" in
        seek_header)
            if [[ "$line" == "###QUARKUS_PROJECT_PACK###" ]]; then
                state=body
            fi
            ;;
        body)
            if [[ "$line" == "###BEGIN###" ]]; then
                state=read_path
            fi
            ;;
        read_path)
            if [[ "$line" == "###PATH:"* ]] && [[ "$line" == *"###" ]]; then
                rest="${line#"###PATH:"}"
                current_path="${rest%###}"
                state=read_header_or_content
            else
                echo "Formato inválido: se esperaba ###PATH:...### tras ###BEGIN###" >&2
                exit 1
            fi
            ;;
        read_header_or_content)
            if [[ "$line" == "###SIZE:"* ]]; then
                # opcional, ignoramos validación estricta (se puede activar)
                state=read_header_or_content
                continue
            fi
            if [[ "$line" == "###CONTENT###" ]]; then
                target="$DEST_ROOT/$current_path"
                mkdir -p "$(dirname "$target")"
                tmpfile="$(mktemp "${TMPDIR:-/tmp}/quarkus-unpack.XXXXXX")"
                state=read_content
            else
                echo "Formato inválido tras PATH: $line" >&2
                exit 1
            fi
            ;;
        read_content)
            if [[ "$line" == "###END###" ]]; then
                mv -f "$tmpfile" "$target"
                tmpfile=""
                current_path=""
                state=body
            elif [[ "$line" == *"###END###" ]]; then
                # pack antiguo: cat sin newline final deja ###END### en la misma línea
                rest="${line%###END###}"
                if [[ -n "$rest" ]]; then
                    printf '%s\n' "$rest" >>"$tmpfile"
                fi
                mv -f "$tmpfile" "$target"
                tmpfile=""
                current_path=""
                state=body
            else
                printf '%s\n' "$line" >>"$tmpfile"
            fi
            ;;
    esac
done <"$INPUT"

if [[ "$state" == "read_content" ]]; then
    if [[ -n "${tmpfile:-}" ]] && [[ -f "$tmpfile" ]]; then
        mv -f "$tmpfile" "$target"
        echo "Advertencia: archivo truncado al final del pack: $current_path" >&2
        tmpfile=""
        state=body
    fi
fi

if [[ "$state" != "body" && "$state" != "seek_header" ]]; then
    echo "Archivo truncado o incompleto (estado: $state)" >&2
    exit 1
fi

echo "Proyecto extraído en: $DEST_ROOT" >&2
