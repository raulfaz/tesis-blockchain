#!/bin/bash
# scripts/generate-artifacts.sh
# Genera los artefactos necesarios para la red (Fabric 2.5 método tradicional)

set -e

# Directorios
CONFIG_DIR=/home/raul/tesis-blockchain/config
CHANNEL_ARTIFACTS_DIR=/home/raul/tesis-blockchain/channel-artifacts
GENESIS_BLOCK=${CONFIG_DIR}/orderer.genesis.block
CHANNEL_TX=${CHANNEL_ARTIFACTS_DIR}/security-logs-channel.tx

# Exportar ruta de configuración para configtxgen
export FABRIC_CFG_PATH=${CONFIG_DIR}

# Crear carpetas
mkdir -p ${CONFIG_DIR} ${CHANNEL_ARTIFACTS_DIR}

echo "🔧 Generando artefactos para Fabric 2.5 (método tradicional)..."

# PRIMERO: Generar bloque génesis
echo "📝 Generando bloque génesis..."
configtxgen -profile LogNetworkOrdererGenesis -outputBlock ${GENESIS_BLOCK} -channelID system-channel
if [ $? -ne 0 ]; then
    echo "❌ Error al generar bloque génesis"
    exit 1
fi

# SEGUNDO: Generar configuración de transacción del canal
echo "📝 Generando configuración del canal..."
configtxgen -profile SecurityLogsChannel -outputCreateChannelTx ${CHANNEL_TX} -channelID security-logs-channel
if [ $? -ne 0 ]; then
    echo "❌ Error al generar configuración del canal"
    exit 1
fi

# TERCERO: Generar anchor peer updates para LogProvider
echo "⚓ Generando anchor peer para LogProvider..."
configtxgen -profile SecurityLogsChannel -outputAnchorPeersUpdate ${CHANNEL_ARTIFACTS_DIR}/LogProviderMSPanchors.tx -channelID security-logs-channel -asOrg LogProviderMSP
if [ $? -ne 0 ]; then
    echo "❌ Error al generar anchor peer para LogProvider"
    exit 1
fi

# CUARTO: Generar anchor peer updates para LogAuditor
echo "⚓ Generando anchor peer para LogAuditor..."
configtxgen -profile SecurityLogsChannel -outputAnchorPeersUpdate ${CHANNEL_ARTIFACTS_DIR}/LogAuditorMSPanchors.tx -channelID security-logs-channel -asOrg LogAuditorMSP
if [ $? -ne 0 ]; then
    echo "❌ Error al generar anchor peer para LogAuditor"
    exit 1
fi

echo "✅ Artefactos generados correctamente:"
echo "   📁 Génesis: ${GENESIS_BLOCK}"
echo "   📁 Config Canal: ${CHANNEL_TX}"
echo "   ⚓ Anchor LogProvider: ${CHANNEL_ARTIFACTS_DIR}/LogProviderMSPanchors.tx"
echo "   ⚓ Anchor LogAuditor: ${CHANNEL_ARTIFACTS_DIR}/LogAuditorMSPanchors.tx"
echo ""
echo "ℹ️  NOTA: Usando método tradicional para Fabric 2.5"
echo "   Se genera genesis block y archivo de transacción del canal"#!/bin/bash
# scripts/generate-artifacts.sh
# Genera los artefactos necesarios para la red (Channel Participation API)

set -e

# Directorios
CONFIG_DIR=/home/raul/tesis-blockchain/config
CHANNEL_ARTIFACTS_DIR=/home/raul/tesis-blockchain/channel-artifacts
CHANNEL_BLOCK=${CHANNEL_ARTIFACTS_DIR}/security-logs-channel.block

# Exportar ruta de configuración para configtxgen
export FABRIC_CFG_PATH=${CONFIG_DIR}

# Crear carpetas
mkdir -p ${CONFIG_DIR} ${CHANNEL_ARTIFACTS_DIR}

echo "🔧 Generando artefactos para Fabric v3.1.1 usando Channel Participation API..."

# Generar bloque del canal directamente (no se usa genesis block)
echo "📝 Generando bloque del canal..."
configtxgen -profile SecurityLogsChannel -outputBlock ${CHANNEL_BLOCK} -channelID security-logs-channel
if [ $? -ne 0 ]; then
    echo "❌ Error al generar bloque del canal"
    exit 1
fi

# Generar anchor peer updates para LogProvider
echo "⚓ Generando anchor peer para LogProvider..."
configtxgen -profile SecurityLogsChannel -outputAnchorPeersUpdate ${CHANNEL_ARTIFACTS_DIR}/LogProviderMSPanchors.tx -channelID security-logs-channel -asOrg LogProviderMSP
if [ $? -ne 0 ]; then
    echo "❌ Error al generar anchor peer para LogProvider"
    exit 1
fi

# Generar anchor peer updates para LogAuditor
echo "⚓ Generando anchor peer para LogAuditor..."
configtxgen -profile SecurityLogsChannel -outputAnchorPeersUpdate ${CHANNEL_ARTIFACTS_DIR}/LogAuditorMSPanchors.tx -channelID security-logs-channel -asOrg LogAuditorMSP
if [ $? -ne 0 ]; then
    echo "❌ Error al generar anchor peer para LogAuditor"
    exit 1
fi

echo "✅ Artefactos generados correctamente:"
echo "   📁 Bloque Canal: ${CHANNEL_BLOCK}"
echo "   ⚓ Anchor LogProvider: ${CHANNEL_ARTIFACTS_DIR}/LogProviderMSPanchors.tx"
echo "   ⚓ Anchor LogAuditor: ${CHANNEL_ARTIFACTS_DIR}/LogAuditorMSPanchors.tx"
echo ""
echo "ℹ️  NOTA: Fabric v3.1.1 usa Channel Participation API"
echo "   No se genera genesis block, el orderer se inicia sin bootstrap"