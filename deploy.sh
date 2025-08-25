#!/bin/bash

set -e

APP_NAME="mon-app-js"
IMAGE_NAME="mon-app-js:latest"
CONTAINER_NAME="mon-app-js-container"

echo "Déploiement de l'application $APP_NAME"

cleanup() {
    echo "Nettoyage des ressources..."
    docker system prune -f
}

stop_existing() {
    echo "Arrêt du conteneur existant..."
    if docker ps -q -f name=$CONTAINER_NAME; then
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
}

build_image() {
    echo "Construction de l'image Docker..."
    docker build -t $IMAGE_NAME .
}

start_container() {
    echo "Démarrage du nouveau conteneur..."
    docker-compose up -d
}

health_check() {
    echo "Vérification de santé..."
    sleep 10
    
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "Application déployée avec succès!"
    else
        echo "Warning: Health check failed, mais l'application pourrait être en cours de démarrage"
    fi
}

main() {
    echo "===================="
    echo "DÉPLOIEMENT DOCKER"
    echo "===================="
    
    stop_existing
    build_image
    start_container
    health_check
    
    echo ""
    echo "Status des conteneurs:"
    docker ps -f name=$CONTAINER_NAME
    
    echo ""
    echo "Logs récents:"
    docker logs --tail 20 $CONTAINER_NAME
    
    echo ""
    echo "Application disponible sur: http://localhost:3000"
}

case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        echo "Arrêt de l'application..."
        docker-compose down
        ;;
    "logs")
        echo "Affichage des logs..."
        docker logs -f $CONTAINER_NAME
        ;;
    "restart")
        echo "Redémarrage de l'application..."
        docker-compose restart
        ;;
    "clean")
        echo "Nettoyage complet..."
        docker-compose down -v
        docker rmi $IMAGE_NAME 2>/dev/null || true
        cleanup
        ;;
    *)
        echo "Usage: $0 {deploy|stop|logs|restart|clean}"
        echo ""
        echo "Commandes disponibles:"
        echo "  deploy  - Déploie l'application (défaut)"
        echo "  stop    - Arrête l'application"
        echo "  logs    - Affiche les logs en temps réel"
        echo "  restart - Redémarre l'application"
        echo "  clean   - Nettoyage complet (conteneurs + images)"
        exit 1
        ;;
esac
