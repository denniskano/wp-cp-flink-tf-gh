#!/bin/bash

# =============================================================================
# Script para configurar DNS temporalmente solo para Confluent Flink
# =============================================================================

set -e

echo "🔧 Configurando DNS temporal para Confluent Flink..."

# Crear backup del resolv.conf original
if [ ! -f /tmp/resolv.conf.backup ]; then
    echo "📋 Creando backup del resolv.conf original..."
    cp /etc/resolv.conf /tmp/resolv.conf.backup
fi

# Configurar DNS temporal para Confluent Private
echo "🌐 Configurando DNS temporal para Confluent Private..."
cat > /tmp/resolv.conf.temp << EOF
nameserver 10.172.191.71
nameserver 10.0.0.10
nameserver 168.63.129.16
nameserver 127.0.0.53
options edns0
EOF

# Aplicar DNS temporal
echo "⚡ Aplicando DNS temporal..."
cp /tmp/resolv.conf.temp /etc/resolv.conf

echo "✅ DNS configurado temporalmente para Confluent Flink"
echo "📝 Para restaurar: ./scripts/restore-dns.sh"

