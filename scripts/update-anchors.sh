#!/bin/bash
# scripts/update-anchors.sh
# Script para actualizar anchor peers en el canal

set -e

CHANNEL_NAME="security-logs-channel"
ORDERER_URL="orderer.lognetwork.com:7050"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lognetwork.com/tlsca/tlsca.lognetwork.com-cert.pem"

echo "⚓ Actualizando anchor peers para el canal ${CHANNEL_NAME}..."

# Actualizar anchor peer para LogProvider
echo "🔄 Actualizando anchor peer para LogProviderMSP..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="LogProviderMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/users/Admin@logprovider.lognetwork.com/msp
export CORE_PEER_ADDRESS=peer0.logprovider.lognetwork.com:7051

peer channel update \
    -o ${ORDERER_URL} \
    -c ${CHANNEL_NAME} \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/LogProviderMSPanchors.tx \
    --tls \
    --cafile ${ORDERER_CA}

if [ $? -eq 0 ]; then
    echo "✅ Anchor peer para LogProviderMSP actualizado"
else
    echo "❌ Error al actualizar anchor peer para LogProviderMSP"
    exit 1
fi

# Actualizar anchor peer para LogAuditor
echo "🔄 Actualizando anchor peer para LogAuditorMSP..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="LogAuditorMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer0.logauditor.lognetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/users/Admin@logauditor.lognetwork.com/msp
export CORE_PEER_ADDRESS=peer0.logauditor.lognetwork.com:9051

peer channel update \
    -o ${ORDERER_URL} \
    -c ${CHANNEL_NAME} \
    -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/LogAuditorMSPanchors.tx \
    --tls \
    --cafile ${ORDERER_CA}

if [ $? -eq 0 ]; then
    echo "✅ Anchor peer para LogAuditorMSP actualizado"
else
    echo "❌ Error al actualizar anchor peer para LogAuditorMSP"
    exit 1
fi

echo ""
echo "✅ Anchor peers actualizados exitosamente"
echo "📋 Canal ${CHANNEL_NAME} configurado completamente"
echo ""
echo "🔍 Para verificar el canal, usa:"
echo "   peer channel list"
echo "   peer channel getinfo -c ${CHANNEL_NAME}"