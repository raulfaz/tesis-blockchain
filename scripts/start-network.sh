#!/bin/bash
# start-network.sh - Script para iniciar la red blockchain ordenadamente

set -e

DOCKER_COMPOSE_DIR="/home/raul/tesis-blockchain/docker"
DOCKER_COMPOSE_CMD="docker-compose -f $DOCKER_COMPOSE_DIR/docker-compose.yaml"

echo "🚀 Iniciando red blockchain LogNetwork..."

# Limpiar contenedores previos
echo "🧹 Limpiando contenedores previos..."
$DOCKER_COMPOSE_CMD down -v --remove-orphans

# Crear red si no existe
echo "🌐 Creando red lognetwork..."
docker network create lognetwork 2>/dev/null || echo "🔁 Red lognetwork ya existe"

# Iniciar servicios de base de datos primero
echo "📊 Iniciando bases de datos CouchDB..."
$DOCKER_COMPOSE_CMD up -d couchdb0.logprovider couchdb1.logprovider couchdb0.logauditor couchdb1.logauditor

# Esperar que CouchDB esté listo
echo "⏳ Esperando que CouchDB esté listo..."
sleep 30

# Verificar conectividad de CouchDB0
echo "🔍 Verificando conectividad de CouchDB0..."
for i in {1..10}; do
    if curl -f http://localhost:5984/ >/dev/null 2>&1; then
        echo "✅ CouchDB0 está listo"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ CouchDB0 no responde después de 10 intentos"
        exit 1
    fi
    echo "⏳ Intento $i/10 - esperando CouchDB0..."
    sleep 5
done

# Verificar conectividad de CouchDB1
echo "🔍 Verificando conectividad de CouchDB1..."
for i in {1..10}; do
    if curl -f http://localhost:6984/ >/dev/null 2>&1; then
        echo "✅ CouchDB1 está listo"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ CouchDB1 no responde después de 10 intentos"
        exit 1
    fi
    echo "⏳ Intento $i/10 - esperando CouchDB1..."
    sleep 5
done

# Iniciar CAs
echo "🔐 Iniciando Certificate Authorities..."
$DOCKER_COMPOSE_CMD up -d ca.logprovider.lognetwork.com ca.logauditor.lognetwork.com

# Esperar que CAs estén listas
echo "⏳ Esperando que CAs estén listas..."
sleep 10

# Iniciar Orderer
echo "📋 Iniciando Orderer..."
$DOCKER_COMPOSE_CMD up -d orderer.lognetwork.com

# Esperar que Orderer esté listo
echo "⏳ Esperando que Orderer esté listo..."
sleep 15

# Iniciar Peers
echo "🔗 Iniciando Peers..."
$DOCKER_COMPOSE_CMD up -d peer0.logprovider.lognetwork.com peer1.logprovider.lognetwork.com peer0.logauditor.lognetwork.com peer1.logauditor.lognetwork.com

# Esperar que Peers estén listos
echo "⏳ Esperando que Peers estén listos..."
sleep 20

# Iniciar CLI
echo "💻 Iniciando CLI..."
$DOCKER_COMPOSE_CMD up -d cli

# Verificar estado de todos los servicios
echo "🔍 Verificando estado de los servicios..."
$DOCKER_COMPOSE_CMD ps

# Verificar logs de peer1.logprovider específicamente
echo "📝 Verificando logs de peer1.logprovider..."
docker logs peer1.logprovider.lognetwork.com --tail 50

echo "✅ Red blockchain iniciada exitosamente!"
echo ""
echo "🌐 Servicios disponibles:"
echo "  - CouchDB0: http://localhost:5984"
echo "  - CouchDB1: http://localhost:6984"
echo "  - Orderer: localhost:7050"
echo "  - Peer0.LogProvider: localhost:7051"
echo "  - Peer1.LogProvider: localhost:8051"
echo ""
echo "📥 Para acceder al CLI:"
echo "  docker exec -it cli bash"
