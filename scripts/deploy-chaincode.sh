#!/bin/bash
# scripts/deploy-chaincode.sh
# Script completo para instalar y commitear el chaincode de security-logs

set -e

CHANNEL_NAME="security-logs-channel"
CC_NAME="security-logs"
CC_VERSION="1.0"
CC_SEQUENCE=1
CC_PATH="/opt/gopath/src/chaincode/security-logs/"
ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/lognetwork.com/tlsca/tlsca.lognetwork.com-cert.pem"

echo "🚀 Iniciando deployment del chaincode ${CC_NAME}..."

# Función para configurar variables de peer
setGlobalsForLogProvider() {
    export CORE_PEER_LOCALMSPID="LogProviderMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/users/Admin@logprovider.lognetwork.com/msp
    export CORE_PEER_ADDRESS=peer0.logprovider.lognetwork.com:7051
}

setGlobalsForLogAuditor() {
    export CORE_PEER_LOCALMSPID="LogAuditorMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer0.logauditor.lognetwork.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/users/Admin@logauditor.lognetwork.com/msp
    export CORE_PEER_ADDRESS=peer0.logauditor.lognetwork.com:9051
}

# 1. Empaquetar chaincode
echo "📦 Empaquetando chaincode..."
peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_PATH} \
    --lang node \
    --label ${CC_NAME}_${CC_VERSION}

# 2. Instalar en peer0.logprovider
echo "📲 Instalando en peer0.logprovider..."
setGlobalsForLogProvider
peer lifecycle chaincode install ${CC_NAME}.tar.gz

# 3. Instalar en peer1.logprovider
echo "📲 Instalando en peer1.logprovider..."
export CORE_PEER_ADDRESS=peer1.logprovider.lognetwork.com:8051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer1.logprovider.lognetwork.com/tls/ca.crt
peer lifecycle chaincode install ${CC_NAME}.tar.gz

# 4. Instalar en peer0.logauditor
echo "📲 Instalando en peer0.logauditor..."
setGlobalsForLogAuditor
peer lifecycle chaincode install ${CC_NAME}.tar.gz

# 5. Instalar en peer1.logauditor
echo "📲 Instalando en peer1.logauditor..."
export CORE_PEER_ADDRESS=peer1.logauditor.lognetwork.com:10051
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer1.logauditor.lognetwork.com/tls/ca.crt
peer lifecycle chaincode install ${CC_NAME}.tar.gz

# 6. Obtener Package ID
echo "🔍 Obteniendo Package ID..."
setGlobalsForLogProvider
CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep ${CC_NAME}_${CC_VERSION} | awk '{print $3}' | sed 's/,$//')
echo "Package ID: ${CC_PACKAGE_ID}"

# 7. Aprobar para LogProvider
echo "✅ Aprobando para LogProvider..."
setGlobalsForLogProvider
peer lifecycle chaincode approveformyorg \
    -o orderer.lognetwork.com:7050 \
    --ordererTLSHostnameOverride orderer.lognetwork.com \
    --tls \
    --cafile ${ORDERER_CA} \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${CC_PACKAGE_ID} \
    --sequence ${CC_SEQUENCE}

# 8. Aprobar para LogAuditor
echo "✅ Aprobando para LogAuditor..."
setGlobalsForLogAuditor
peer lifecycle chaincode approveformyorg \
    -o orderer.lognetwork.com:7050 \
    --ordererTLSHostnameOverride orderer.lognetwork.com \
    --tls \
    --cafile ${ORDERER_CA} \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${CC_PACKAGE_ID} \
    --sequence ${CC_SEQUENCE}

# 9. Verificar readiness
echo "🔍 Verificando readiness..."
peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --output json

# 10. Commitear chaincode
echo "🚀 Commiteando chaincode..."
peer lifecycle chaincode commit \
    -o orderer.lognetwork.com:7050 \
    --ordererTLSHostnameOverride orderer.lognetwork.com \
    --tls \
    --cafile ${ORDERER_CA} \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --peerAddresses peer0.logprovider.lognetwork.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt \
    --peerAddresses peer0.logauditor.lognetwork.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer0.logauditor.lognetwork.com/tls/ca.crt \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE}

# 11. Verificar instalación
echo "🔍 Verificando instalación final..."
peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME}

# 12. Inicializar ledger
echo "🏁 Inicializando ledger..."
setGlobalsForLogProvider
peer chaincode invoke \
    -o orderer.lognetwork.com:7050 \
    --ordererTLSHostnameOverride orderer.lognetwork.com \
    --tls \
    --cafile ${ORDERER_CA} \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    --peerAddresses peer0.logprovider.lognetwork.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logprovider.lognetwork.com/peers/peer0.logprovider.lognetwork.com/tls/ca.crt \
    --peerAddresses peer0.logauditor.lognetwork.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/logauditor.lognetwork.com/peers/peer0.logauditor.lognetwork.com/tls/ca.crt \
    -c '{"function":"initLedger","Args":[]}'

echo ""
echo "✅ Chaincode ${CC_NAME} deployado exitosamente!"
echo "📋 Para probar:"
echo "   peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"function\":\"queryAllSecurityLogs\",\"Args\":[]}'"
