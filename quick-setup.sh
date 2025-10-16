#!/bin/bash
set -e

# ============================================================================
# Script d'initialisation rapide pour environnements éphémères ArgoCD
# ============================================================================
# Prérequis : kubectl + k3s déjà installés
# Usage : GITHUB_TOKEN=ghp_xxx ./quick-setup.sh
# ============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

GITHUB_REPO="https://github.com/axelfrache/cicd-project.git"
REPO_OWNER="axelfrache"
REPO_NAME="cicd-project"

# ============================================================================
# Vérifications
# ============================================================================

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo -e "${RED}✗${NC} Variable GITHUB_TOKEN non définie"
    echo ""
    echo "Usage :"
    echo "  export GITHUB_TOKEN=ghp_votre_token"
    echo "  ./quick-setup.sh"
    echo ""
    echo "Ou en une ligne :"
    echo "  GITHUB_TOKEN=ghp_votre_token ./quick-setup.sh"
    echo ""
    echo "Créer un token : https://github.com/settings/tokens/new"
    echo "Scope requis : public_repo (ou repo si privé)"
    exit 1
fi

if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}✗${NC} kubectl non trouvé. Installez-le d'abord."
    exit 1
fi

if ! kubectl get nodes &>/dev/null; then
    echo -e "${RED}✗${NC} kubectl ne peut pas se connecter au cluster"
    exit 1
fi

echo -e "${GREEN}✓${NC} kubectl fonctionne"
echo -e "${GREEN}✓${NC} Token GitHub fourni"
echo ""

# ============================================================================
# Installation ArgoCD
# ============================================================================

echo -e "${BOLD}${BLUE}[1/7]${NC} Installation ArgoCD..."

if kubectl get namespace argocd &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} ArgoCD déjà installé, on skip"
else
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo -e "${GREEN}✓${NC} ArgoCD installé"
fi

echo "Attente du démarrage d'ArgoCD (30s)..."
sleep 30

kubectl wait --for=condition=Ready pods -n argocd -l app.kubernetes.io/name=argocd-server --timeout=180s 2>/dev/null || true
echo -e "${GREEN}✓${NC} ArgoCD prêt"
echo ""

# ============================================================================
# Installation ArgoCD CLI
# ============================================================================

echo -e "${BOLD}${BLUE}[2/7]${NC} Installation ArgoCD CLI..."

if command -v argocd &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} ArgoCD CLI déjà installé"
else
    curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 755 /tmp/argocd /usr/local/bin/argocd
    rm /tmp/argocd
    echo -e "${GREEN}✓${NC} ArgoCD CLI installé"
fi
echo ""

# ============================================================================
# Connexion ArgoCD CLI
# ============================================================================

echo -e "${BOLD}${BLUE}[3/7]${NC} Connexion ArgoCD CLI..."

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

kubectl port-forward -n argocd svc/argocd-server 8080:443 >/dev/null 2>&1 &
PF_PID=$!
sleep 5

argocd login localhost:8080 \
    --username admin \
    --password "${ARGOCD_PASSWORD}" \
    --insecure >/dev/null 2>&1 || true

kill $PF_PID 2>/dev/null || true

echo -e "${GREEN}✓${NC} Connecté à ArgoCD"
echo ""

# ============================================================================
# Configuration token GitHub
# ============================================================================

echo -e "${BOLD}${BLUE}[4/7]${NC} Configuration token GitHub..."

kubectl delete secret -n argocd github-token --ignore-not-found
kubectl -n argocd create secret generic github-token --from-literal=token="${GITHUB_TOKEN}"

echo -e "${GREEN}✓${NC} Token GitHub configuré"
echo ""

# ============================================================================
# Ajout du repository ArgoCD
# ============================================================================

echo -e "${BOLD}${BLUE}[5/7]${NC} Ajout du repository dans ArgoCD..."

argocd repo add "${GITHUB_REPO}" \
    --username "${REPO_OWNER}" \
    --password "${GITHUB_TOKEN}" 2>/dev/null || true

echo -e "${GREEN}✓${NC} Repository ajouté"
echo ""

# ============================================================================
# Clone du repository
# ============================================================================

echo -e "${BOLD}${BLUE}[6/7]${NC} Clonage du repository..."

REPO_DIR="/tmp/${REPO_NAME}"
rm -rf "${REPO_DIR}"
git clone "${GITHUB_REPO}" "${REPO_DIR}" >/dev/null 2>&1

echo -e "${GREEN}✓${NC} Repository cloné"
echo ""

# ============================================================================
# Déploiement des configurations ArgoCD
# ============================================================================

echo -e "${BOLD}${BLUE}[7/7]${NC} Déploiement des configurations..."

# Détection de l'IP du serveur
echo -e "${YELLOW}⏳${NC} Détection de l'IP du serveur..."
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n1)

if [[ -z "$SERVER_IP" ]]; then
    echo -e "${YELLOW}⚠${NC} Impossible de détecter l'IP automatiquement"
    read -p "Entrez l'IP de ce serveur (ex: 192.168.1.100): " SERVER_IP
fi

echo -e "${GREEN}✓${NC} IP du serveur : ${YELLOW}${SERVER_IP}${NC}"
echo -e "${BLUE}ℹ${NC} Les applications seront accessibles via : ${YELLOW}pr-XX.${SERVER_IP}.nip.io${NC}"

# Configurer l'IP dans l'ApplicationSet
sed -i "s/SERVER_IP/${SERVER_IP}/g" "${REPO_DIR}/argo/appset-prs.yaml"

# Projet ArgoCD
kubectl apply -f "${REPO_DIR}/argo/project.yaml"
echo -e "${GREEN}✓${NC} Projet springcity créé"

# ApplicationSet pour les PRs
kubectl apply -f "${REPO_DIR}/argo/appset-prs.yaml"
echo -e "${GREEN}✓${NC} ApplicationSet déployé"

# Application statique
kubectl apply -f "${REPO_DIR}/argo/app-static.yaml"
echo -e "${GREEN}✓${NC} Application statique déployée"

echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}    ✓ Installation terminée avec succès !${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# Résumé
# ============================================================================

echo -e "${BOLD}Informations importantes :${NC}"
echo ""
echo -e "  ${BLUE}•${NC} Mot de passe ArgoCD admin : ${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo -e "  ${BLUE}•${NC} Interface ArgoCD : ${YELLOW}https://localhost:8080${NC}"
echo -e "  ${BLUE}•${NC} IP du serveur : ${YELLOW}${SERVER_IP}${NC}"
echo -e "  ${BLUE}•${NC} Repository : ${YELLOW}${GITHUB_REPO}${NC}"
echo -e "  ${BLUE}•${NC} URL d'accès PRs : ${YELLOW}http://pr-XX.${SERVER_IP}.nip.io${NC}"
echo ""

echo -e "${BOLD}Accéder à l'interface ArgoCD :${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n argocd svc/argocd-server 8080:443${NC}"
echo ""

echo -e "${BOLD}Commandes utiles :${NC}"
echo ""
echo -e "  ${YELLOW}# Lister les applications${NC}"
echo -e "  argocd app list"
echo ""
echo -e "  ${YELLOW}# Surveiller les applications${NC}"
echo -e "  watch -n 5 \"argocd app list\""
echo ""
echo -e "  ${YELLOW}# Voir les pods d'une PR${NC}"
echo -e "  kubectl get pods -n springcity-pr-10"
echo ""
echo -e "  ${YELLOW}# Voir les logs d'une PR${NC}"
echo -e "  kubectl logs -n springcity-pr-10 -l app.kubernetes.io/name=springcity --tail=50"
echo ""

echo -e "${BOLD}Comment ça marche ?${NC}"
echo ""
echo -e "  ${BLUE}1.${NC} Créez une Pull Request sur GitHub"
echo -e "  ${BLUE}2.${NC} GitHub Actions build l'image Docker ${YELLOW}pr-XX${NC}"
echo -e "  ${BLUE}3.${NC} ArgoCD détecte la PR (max 60s)"
echo -e "  ${BLUE}4.${NC} Un environnement ${YELLOW}springcity-pr-XX${NC} est créé automatiquement"
echo -e "  ${BLUE}5.${NC} Accessible via ${YELLOW}http://pr-XX.${SERVER_IP}.nip.io${NC}"
echo -e "  ${BLUE}6.${NC} À la fermeture de la PR, l'environnement est supprimé"
echo ""
echo -e "${BOLD}${BLUE}ℹ${NC} Accès depuis n'importe quelle machine du réseau${NC}"
echo -e "  Les applications sont accessibles depuis tout le réseau local"
echo -e "  Exemple : ${YELLOW}http://pr-10.${SERVER_IP}.nip.io${NC}"
echo ""

echo -e "${BOLD}${GREEN}Testez maintenant en créant une PR !${NC} 🚀"
echo ""
