#!/bin/bash
# scripts/reset-network.sh
# Script para reiniciar completamente la red y solucionar problemas

set -e

echo "🔄 Reiniciando red blockchain completamente..."

# 1. Parar todos los contenedores
echo "🛑 Parando contenedores..."
docker-compose -f docker/docker-compose.yaml down -v

# 2. Limpiar volúmenes y redes
echo "🧹 Limpiando volúmenes y redes..."
docker volume prune -f
docker network prune -f

# 3. Limpiar imágenes de chaincode antiguas
echo "🗑️  Limpiando imágenes de chaincode..."
docker rmi $(docker images | grep dev-peer | awk '{print $3}') 2>/dev/null || true

# 4. Recrear red
echo "🌐 Recreando red..."
docker network create lognetwork 2>/dev/null || true

# 5. Iniciar servicios en orden correcto
echo "🚀 Iniciando servicios..."

# CouchDB primero
echo "📊 Iniciando CouchDB..."
docker-compose -f docker/docker-compose.yaml up -d couchdb0.logprovider couchdb1.logprovider couchdb0.logauditor couchdb1.logauditor

# Esperar CouchDB
echo "⏳ Esperando CouchDB..."
sleep 20

# CAs
echo "🔐 Iniciando CAs..."
docker-compose -f docker/docker-compose.yaml up -d ca.logprovider.lognetwork.com ca.logauditor.lognetwork.com
sleep 10

# Orderer
echo "📋 Iniciando Orderer..."
docker-compose -f docker/docker-compose.yaml up -d orderer.lognetwork.com
sleep 15

# Peers
echo "🔗 Iniciando Peers..."
docker-compose -f docker/docker-compose.yaml up -d peer0.logprovider.lognetwork.com peer1.logprovider.lognetwork.com peer0.logauditor.lognetwork.com peer1.logauditor.lognetwork.com
sleep 20

# CLI
echo "💻 Iniciando CLI..."
docker-compose -f docker/docker-compose.yaml up -d cli

# 6. Verificar estado
echo "🔍 Verificando estado de la red..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 7. Verificar logs críticos
echo "📝 Verificando logs del orderer..."
docker logs orderer.lognetwork.com --tail 5

echo "📝 Verificando logs de peer0..."
docker logs peer0.logprovider.lognetwork.com --tail 5

echo ""
echo "✅ Red reiniciada completamente"
echo ""
echo "📋 Próximos pasos:"
echo "1. docker exec -it cli bash"
echo "2. ./scripts/create-channel.sh"
echo "3. ./scripts/join-channel.sh"
echo "4. ./scripts/update-anchors.sh"