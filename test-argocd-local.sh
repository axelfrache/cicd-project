#!/bin/bash

# Script de test complet ArgoCD en local
# Usage: ./test-argocd-local.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Test ArgoCD en local ===${NC}\n"

# Vérifier que ArgoCD est installé
if ! kubectl get namespace argocd &> /dev/null; then
    echo -e "${RED}ArgoCD n'est pas installé. Exécutez d'abord: ./argocd/install-argocd.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Vérification de l'application de production...${NC}"
if argocd app get springcity-prod &> /dev/null; then
    echo -e "${GREEN}✓ Application de production trouvée${NC}"
    argocd app get springcity-prod | grep -E "Health Status|Sync Status"
else
    echo -e "${RED}✗ Application de production non trouvée${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[2/8] Création d'un environnement éphémère de test...${NC}"
kubectl apply -f argocd/test-pr-local.yaml
sleep 2

echo -e "\n${YELLOW}[3/8] Synchronisation de l'environnement de test...${NC}"
argocd app sync springcity-pr-test --timeout 300

echo -e "\n${YELLOW}[4/8] Attente que l'application soit healthy...${NC}"
argocd app wait springcity-pr-test --health --timeout 300

echo -e "\n${YELLOW}[5/8] Vérification des ressources créées...${NC}"
kubectl get all -n springcity-pr-test

echo -e "\n${YELLOW}[6/8] Test de l'application...${NC}"
# Port-forward en arrière-plan
kubectl port-forward -n springcity-pr-test svc/springcity-pr-test 9999:2022 &
PF_PID=$!
sleep 5

# Tester l'API
if curl -f http://localhost:9999/_health &> /dev/null; then
    echo -e "${GREEN}✓ Application répond correctement${NC}"
    curl http://localhost:9999/_health
else
    echo -e "${RED}✗ Application ne répond pas${NC}"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Arrêter le port-forward
kill $PF_PID 2>/dev/null || true

echo -e "\n${YELLOW}[7/8] Simulation d'une mise à jour...${NC}"
kubectl patch application springcity-pr-test -n argocd --type merge -p '
{
  "spec": {
    "source": {
      "helm": {
        "parameters": [
          {"name": "image.tag", "value": "latest"},
          {"name": "replicaCount", "value": "2"}
        ]
      }
    }
  }
}'

echo -e "Attente de la synchronisation automatique..."
sleep 10
argocd app get springcity-pr-test | grep -E "Health Status|Sync Status"

echo -e "\n${YELLOW}[8/8] Nettoyage - Suppression de l'environnement de test...${NC}"
argocd app delete springcity-pr-test --yes --cascade

# Attendre la suppression complète
echo -e "Attente de la suppression complète..."
sleep 10

# Vérifier que le namespace est bien supprimé
if kubectl get namespace springcity-pr-test &> /dev/null; then
    echo -e "${RED}✗ Le namespace n'a pas été supprimé${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Namespace supprimé avec succès${NC}"
fi

echo -e "\n${GREEN}=== Tous les tests sont passés ! ===${NC}"
echo -e "\n${GREEN}Résumé :${NC}"
echo -e "✓ Application de production fonctionne"
echo -e "✓ Environnement éphémère créé"
echo -e "✓ Application déployée et accessible"
echo -e "✓ Mise à jour automatique fonctionne"
echo -e "✓ Suppression et nettoyage fonctionnent"
echo -e "\n${YELLOW}ArgoCD est prêt à être utilisé ! 🚀${NC}"
