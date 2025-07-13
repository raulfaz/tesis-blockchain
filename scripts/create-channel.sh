#!/bin/bash
# scripts/create-channel.sh
# Script para crear el canal usando método tradicional (Fabric 2.5)

set -e

# Configuración
CHANNEL_NAME="security-logs-channel"
ORDERER_URL="orderer.lognetwork.com:7050"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lognetwork.com/tlsca/tlsca.lognetwork.com-cert.pem"
CHANNEL_TX="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/security-logs-channel.tx"

# Configuración del peer LogProvider
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="LogProviderMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/users/Admin@logprovider.lognetwork.com/msp
export CORE_PEER_ADDRESS=peer0.logprovider.lognetwork.com:7051

echo "🚀 Creando canal ${CHANNEL_NAME} usando método tradicional (Fabric 2.5)..."

# Verificar que el archivo de configuración del canal existe
if [ ! -f "$CHANNEL_TX" ]; then
    echo "❌ Archivo de configuración del canal no encontrado: $CHANNEL_TX"
    echo "   El archivo debe generarse con: configtxgen -outputCreateChannelTx"
    exit 1
fi

# Verificar que el certificado CA del orderer existe
if [ ! -f "$ORDERER_CA" ]; then
    echo "❌ Certificado CA del orderer no encontrado: $ORDERER_CA"
    exit 1
fi

echo "✅ Archivos verificados correctamente"
echo "📁 Configuración del canal: $CHANNEL_TX"
echo "🔑 CA del orderer: $ORDERER_CA"

# Crear el canal usando peer channel create (método tradicional)
echo "📝 Creando canal usando peer channel create..."
peer channel create \
    -o ${ORDERER_URL} \
    -c ${CHANNEL_NAME} \
    -f ${CHANNEL_TX} \
    --outputBlock /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block \
    --tls \
    --cafile ${ORDERER_CA}

if [ $? -eq 0 ]; then
    echo "✅ Canal ${CHANNEL_NAME} creado exitosamente"
    echo "📁 Bloque del canal guardado en: channel-artifacts/${CHANNEL_NAME}.block"
else
    echo "❌ Error al crear el canal ${CHANNEL_NAME}"
    echo "💡 Verificar logs del orderer: docker logs orderer.lognetwork.com"
    exit 1
fi

echo ""
echo "📋 Pasos siguientes:"
echo "1. Unir peers al canal usando: ./join-channel.sh"
echo "2. Actualizar anchor peers usando: ./update-anchors.sh"