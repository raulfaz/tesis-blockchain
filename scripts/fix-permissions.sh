#!/bin/bash
# scripts/fix-permissions.sh
# Corrige permisos de archivos críticos

set -e

echo "🔧 Corrigiendo permisos de archivos..."

# Directorio base
BASE_DIR="/home/raul/tesis-blockchain"

# Corregir permisos de certificados
echo "🔐 Corrigiendo permisos de certificados..."
sudo chown -R $(whoami):$(whoami) ${BASE_DIR}/crypto/
sudo chmod -R 755 ${BASE_DIR}/crypto/
sudo find ${BASE_DIR}/crypto/ -name "*.key" -exec chmod 600 {} \;
sudo find ${BASE_DIR}/crypto/ -name "priv_sk" -exec chmod 600 {} \;

# Corregir permisos de scripts
echo "📝 Corrigiendo permisos de scripts..."
sudo chmod +x ${BASE_DIR}/scripts/*.sh

# Corregir permisos de archivos de configuración
echo "⚙️ Corrigiendo permisos de configuración..."
sudo chown -R $(whoami):$(whoami) ${BASE_DIR}/config/
sudo chown -R $(whoami):$(whoami) ${BASE_DIR}/channel-artifacts/

echo "✅ Permisos corregidos"