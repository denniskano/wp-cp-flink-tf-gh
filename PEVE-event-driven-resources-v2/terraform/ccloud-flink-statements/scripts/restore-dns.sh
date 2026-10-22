#!/bin/bash

# =============================================================================
# Script para restaurar DNS original
# =============================================================================

set -e

echo "🔄 Restaurando DNS original..."

# Verificar si existe el backup
if [ ! -f /tmp/resolv.conf.backup ]; then
    echo "❌ No se encontró backup del resolv.conf original"
    echo "💡 Ejecuta primero: ./scripts/configure-dns.sh"
    exit 1
fi

# Restaurar DNS original
echo "📋 Restaurando resolv.conf original..."
cp /tmp/resolv.conf.backup /etc/resolv.conf

# Limpiar archivos temporales
echo "🧹 Limpiando archivos temporales..."
rm -f /tmp/resolv.conf.temp

echo "✅ DNS restaurado exitosamente"

