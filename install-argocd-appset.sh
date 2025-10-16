#!/bin/bash

# Script d'installation ArgoCD avec ApplicationSet pour SpringCity
# Usage: ./install-argocd-appset.sh [GITHUB_TOKEN]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

GITHUB_TOKEN=$1

echo -e "${GREEN}=== Installation ArgoCD avec ApplicationSet ===${NC}\n"

# Vérifier que kubectl fonctionne
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Impossible de se connecter au cluster Kubernetes${NC}"
    echo -e "${YELLOW}Assurez-vous que K3s est installé et configuré${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connexion au cluster Kubernetes OK${NC}\n"

# 1. Créer le namespace ArgoCD
echo -e "${YELLOW}[1/6] Création du namespace argocd...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Installer ArgoCD
echo -e "${YELLOW}[2/6] Installation d'ArgoCD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Attendre que les pods soient prêts
echo -e "${YELLOW}[3/6] Attente du démarrage d'ArgoCD (cela peut prendre 3-5 minutes)...${NC}"
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s

echo -e "${GREEN}✓ ArgoCD installé et prêt${NC}\n"

# 4. Créer le secret GitHub si un token est fourni
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}[4/6] Configuration du token GitHub...${NC}"
    kubectl create secret generic github-token -n argocd \
        --from-literal=token=$GITHUB_TOKEN \
        --dry-run=client -o yaml | kubectl apply -f -
    echo -e "${GREEN}✓ Token GitHub configuré${NC}"
else
    echo -e "${YELLOW}[4/6] Pas de token GitHub fourni (optionnel)${NC}"
    echo -e "${YELLOW}Pour éviter le rate-limit, créez un token GitHub et relancez :${NC}"
    echo -e "${YELLOW}  ./install-argocd-appset.sh ghp_VOTRE_TOKEN${NC}"
fi

# 5. Appliquer les manifests ArgoCD
echo -e "\n${YELLOW}[5/6] Application des manifests ArgoCD...${NC}"

kubectl apply -f argo/project.yaml
echo -e "${GREEN}✓ Projet SpringCity créé${NC}"

kubectl apply -f argo/app-static.yaml
echo -e "${GREEN}✓ Application statique créée${NC}"

kubectl apply -f argo/appset-prs.yaml
echo -e "${GREEN}✓ ApplicationSet PR créé${NC}"

# 6. Récupérer les informations de connexion
echo -e "\n${YELLOW}[6/6] Récupération des informations de connexion...${NC}"

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "\n${GREEN}=== Installation terminée avec succès ! ===${NC}\n"

echo -e "${GREEN}Informations de connexion ArgoCD:${NC}"
echo -e "  URL       : ${GREEN}https://localhost:8080${NC}"
echo -e "  Username  : ${GREEN}admin${NC}"
echo -e "  Password  : ${GREEN}${ARGOCD_PASSWORD}${NC}"
echo ""

echo -e "${YELLOW}Pour accéder à l'interface ArgoCD :${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n argocd svc/argocd-server 8080:443${NC}"
echo -e "  ${YELLOW}Puis ouvrir : https://localhost:8080${NC}"
echo ""

echo -e "${GREEN}Applications déployées :${NC}"
echo -e "  • ${GREEN}springcity-static${NC} → Environnement statique (toujours actif)"
echo -e "  • ${GREEN}springcity-prs${NC} → ApplicationSet pour les PRs (auto)"
echo ""

echo -e "${YELLOW}Vérifier les applications :${NC}"
echo -e "  ${YELLOW}kubectl get applications -n argocd${NC}"
echo -e "  ${YELLOW}kubectl get all -n springcity-static${NC}"
echo ""

echo -e "${GREEN}Environnement statique accessible sur :${NC}"
echo -e "  • ${GREEN}http://springcity.127.0.0.1.nip.io${NC} (avec Traefik)"
echo -e "  • Port-forward : ${YELLOW}kubectl port-forward -n springcity-static svc/springcity-static 2022:2022${NC}"
echo ""

echo -e "${YELLOW}Les PRs créeront automatiquement des environnements sur :${NC}"
echo -e "  • ${GREEN}http://pr-<NUMBER>.127.0.0.1.nip.io${NC}"
echo ""

echo -e "${GREEN}Documentation complète : argo/README.md${NC}"
