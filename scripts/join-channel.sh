#!/bin/bash
# scripts/join-channel.sh
# Script para unir todos los peers al canal

set -e

CHANNEL_NAME="security-logs-channel"
CHANNEL_BLOCK="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.block"

echo "🔗 Uniendo peers al canal ${CHANNEL_NAME}..."

# Verificar que el bloque del canal existe
if [ ! -f "$CHANNEL_BLOCK" ]; then
    echo "❌ Bloque del canal no encontrado: $CHANNEL_BLOCK"
    echo "   Ejecuta primero: ./create-channel.sh"
    exit 1
fi

# Función para unir un peer al canal
join_peer() {
    local ORG_MSP=$1
    local PEER_ADDRESS=$2
    local PEER_NAME=$3
    local TLS_CERT=$4
    local MSP_PATH=$5
    
    echo "🔌 Uniendo ${PEER_NAME} (${ORG_MSP}) al canal..."
    
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID=${ORG_MSP}
    export CORE_PEER_TLS_ROOTCERT_FILE=${TLS_CERT}
    export CORE_PEER_MSPCONFIGPATH=${MSP_PATH}
    export CORE_PEER_ADDRESS=${PEER_ADDRESS}
    
    peer channel join -b ${CHANNEL_BLOCK}
    
    if [ $? -eq 0 ]; then
        echo "✅ ${PEER_NAME} unido exitosamente"
    else
        echo "❌ Error al unir ${PEER_NAME}"
        return 1
    fi
}

# Unir peer0.logprovider
join_peer \
    "LogProviderMSP" \
    "peer0.logprovider.lognetwork.com:7051" \
    "peer0.logprovider" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/users/Admin@logprovider.lognetwork.com/msp"

# Unir peer1.logprovider
join_peer \
    "LogProviderMSP" \
    "peer1.logprovider.lognetwork.com:8051" \
    "peer1.logprovider" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer1.logprovider.lognetwork.com/tls/ca.crt" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/users/Admin@logprovider.lognetwork.com/msp"

# Unir peer0.logauditor
join_peer \
    "LogAuditorMSP" \
    "peer0.logauditor.lognetwork.com:9051" \
    "peer0.logauditor" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer0.logauditor.lognetwork.com/tls/ca.crt" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/users/Admin@logauditor.lognetwork.com/msp"

# Unir peer1.logauditor
join_peer \
    "LogAuditorMSP" \
    "peer1.logauditor.lognetwork.com:10051" \
    "peer1.logauditor" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer1.logauditor.lognetwork.com/tls/ca.crt" \
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/users/Admin@logauditor.lognetwork.com/msp"

echo ""
echo "✅ Todos los peers unidos al canal ${CHANNEL_NAME}"
echo "📋 Siguiente paso: Actualizar anchor peers usando: ./update-anchors.sh"