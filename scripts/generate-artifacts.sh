#!/bin/bash
# scripts/generate-artifacts.sh
# Genera los artefactos necesarios para la red

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

# Generar bloque génesis
echo "Generando bloque génesis..."
configtxgen -profile LogNetworkOrdererGenesis -outputBlock ${GENESIS_BLOCK} -channelID system-channel
if [ $? -ne 0 ]; then
    echo "Error al generar bloque génesis"
    exit 1
fi

# Generar configuración del canal
echo "Generando configuración del canal..."
configtxgen -profile SecurityLogsChannel -outputCreateChannelTx ${CHANNEL_TX} -channelID security-logs-channel
if [ $? -ne 0 ]; then
    echo "Error al generar configuración del canal"
    exit 1
fi

echo "✅ Artefactos generados correctamente en:"
echo "   Génesis: ${GENESIS_BLOCK}"
echo "   Canal:   ${CHANNEL_TX}"
