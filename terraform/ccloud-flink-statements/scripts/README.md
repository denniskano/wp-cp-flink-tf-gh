# Scripts de DNS para Confluent Flink

## 📋 Descripción

Estos scripts permiten configurar DNS temporalmente solo para Confluent Flink, sin afectar otros servicios como Vault.

## 🔧 Scripts Disponibles

### `configure-dns.sh`
Configura DNS temporal para Confluent Flink:
- Crea backup del `resolv.conf` original
- Configura DNS con `8.8.8.8` y `1.1.1.1`
- Aplica la configuración temporal

### `restore-dns.sh`
Restaura la configuración DNS original:
- Restaura el `resolv.conf` original desde el backup
- Limpia archivos temporales
- Requiere que se haya ejecutado `configure-dns.sh` primero

## 🚀 Uso

### En GitHub Actions (automático)
Los scripts se ejecutan automáticamente en el workflow:
1. **Antes de Terraform**: `configure-dns.sh`
2. **Después de Terraform**: `restore-dns.sh` (siempre, incluso si falla)

### En local (manual)
```bash
# 1. Dar permisos de ejecución
chmod +x scripts/*.sh

# 2. Configurar DNS temporal
sudo ./scripts/configure-dns.sh

# 3. Ejecutar Terraform
terraform apply

# 4. Restaurar DNS original
sudo ./scripts/restore-dns.sh
```

## ⚠️ Importante

- **Siempre ejecutar `restore-dns.sh`** después de usar `configure-dns.sh`
- Los scripts requieren permisos de `sudo`
- El backup se guarda en `/tmp/resolv.conf.backup`

## 🔍 Troubleshooting

### Error: "No se encontró backup"
```bash
# Solución: Ejecutar configure-dns.sh primero
sudo ./scripts/configure-dns.sh
```

### Error: "Permission denied"
```bash
# Solución: Dar permisos de ejecución
chmod +x scripts/*.sh

# En GitHub Actions: Se hace automáticamente
# En local: Ejecutar manualmente antes de usar los scripts
```

## 📁 Estructura

```
scripts/
├── configure-dns.sh    # Configurar DNS temporal
├── restore-dns.sh      # Restaurar DNS original
└── README.md          # Esta documentación
```
