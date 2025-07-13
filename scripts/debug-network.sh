#!/bin/bash
# scripts/debug-network.sh
# Script para diagnosticar problemas en la red

set -e

echo "🔍 Diagnóstico de la red blockchain..."

echo "1. 📊 Estado de contenedores:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "2. 🔗 Verificando conectividad de red:"
docker network ls | grep lognetwork

echo ""
echo "3. 📝 Logs recientes del orderer:"
echo "--- Últimas 10 líneas ---"
docker logs orderer.lognetwork.com --tail 10

echo ""
echo "4. 📝 Logs recientes de peer0.logprovider:"
echo "--- Últimas 10 líneas ---"
docker logs peer0.logprovider.lognetwork.com --tail 10

echo ""
echo "5. 🗃️ Verificando volúmenes de datos:"
docker volume ls | grep lognetwork

echo ""
echo "6. 🔍 Verificando archivos críticos en CLI:"
docker exec cli ls -la /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/

echo ""
echo "7. 🔐 Verificando certificados en peer0:"
docker exec peer0.logprovider.lognetwork.com ls -la /etc/hyperledger/fabric/msp/

echo ""
echo "8. 📡 Test de conectividad entre peers:"
docker exec cli ping -c 3 peer0.logprovider.lognetwork.com
docker exec cli ping -c 3 orderer.lognetwork.com

echo ""
echo "9. 🔍 Verificando configuración de peer desde CLI:"
docker exec cli peer version

echo ""
echo "✅ Diagnóstico completado"