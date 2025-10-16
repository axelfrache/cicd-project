#!/bin/bash

# Script d'installation complète K3s + ArgoCD
# Usage: ./install-k3s-argocd.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Installation K3s + ArgoCD ===${NC}\n"

# Vérifier qu'on est sur Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}Ce script doit être exécuté sur Linux${NC}"
    exit 1
fi

# Vérifier si K3s est déjà installé
if command -v k3s &> /dev/null; then
    echo -e "${GREEN}✓ K3s est déjà installé${NC}"
    
    # Vérifier que K3s tourne
    if sudo systemctl is-active --quiet k3s; then
        echo -e "${GREEN}✓ K3s est actif${NC}"
    else
        echo -e "${YELLOW}K3s est installé mais pas actif, démarrage...${NC}"
        sudo systemctl start k3s
        sleep 10
    fi
else
    echo -e "${YELLOW}[1/4] Installation de K3s...${NC}"
    curl -sfL https://get.k3s.io | sh -
    
    echo -e "${YELLOW}Attente du démarrage de K3s...${NC}"
    sleep 15
    
    # Vérifier que K3s a bien démarré
    if sudo systemctl is-active --quiet k3s; then
        echo -e "${GREEN}✓ K3s installé et démarré${NC}"
    else
        echo -e "${RED}✗ Erreur lors du démarrage de K3s${NC}"
        echo -e "${YELLOW}Logs K3s:${NC}"
        sudo journalctl -u k3s -n 50 --no-pager
        exit 1
    fi
fi

echo -e "\n${YELLOW}[2/4] Configuration de kubectl...${NC}"

# Créer le dossier .kube
mkdir -p ~/.kube

# Copier la configuration
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Vérifier la connexion
echo -e "${YELLOW}Test de la connexion kubectl...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✓ kubectl configuré avec succès${NC}"
else
    echo -e "${RED}✗ Impossible de se connecter au cluster${NC}"
    exit 1
fi

# Attendre que le cluster soit prêt
echo -e "${YELLOW}Attente que le cluster soit complètement prêt...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "\n${YELLOW}[3/4] Vérification du cluster...${NC}"
kubectl get nodes
kubectl get pods -A

echo -e "\n${YELLOW}[4/4] Installation d'ArgoCD...${NC}"

# Vérifier qu'on est dans le bon dossier
if [ ! -f "argocd/install-argocd.sh" ]; then
    echo -e "${RED}Erreur: Le script doit être exécuté depuis le dossier cicd-project${NC}"
    exit 1
fi

# Lancer l'installation ArgoCD
chmod +x argocd/install-argocd.sh
./argocd/install-argocd.sh

echo -e "\n${GREEN}=== Installation terminée ! ===${NC}"
echo -e "\n${YELLOW}Commandes utiles :${NC}"
echo -e "  kubectl get nodes              # Voir les nodes"
echo -e "  kubectl get pods -A            # Voir tous les pods"
echo -e "  argocd app list                # Lister les applications ArgoCD"
echo -e "  kubectl get all -n springcity-prod  # Voir l'application de prod"
