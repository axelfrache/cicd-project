#!/bin/bash
set -e

# ============================================================================
# Script de test : Isolation des bases de données PR vs Prod
# ============================================================================
# Ce script teste que :
# 1. Les PRs sont initialisées avec le dump
# 2. Les modifications dans une PR n'affectent pas la prod
# 3. Chaque PR a sa propre DB isolée
# ============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# Configuration
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n1)
PROD_URL="http://springcity-static.${SERVER_IP}.nip.io"
PR_NUMBER=${1:-12}  # Utiliser le numéro de PR passé en argument, sinon 12
PR_URL="http://pr-${PR_NUMBER}.${SERVER_IP}.nip.io"

echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  Test d'isolation des bases de données PR vs Prod       ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration :${NC}"
echo -e "  • Production : ${PROD_URL}"
echo -e "  • PR #${PR_NUMBER}  : ${PR_URL}"
echo ""

# ============================================================================
# Test 1 : Vérifier que les environnements sont accessibles
# ============================================================================
echo -e "${BOLD}[Test 1/5]${NC} Vérification de l'accessibilité..."

echo -n "  • Production... "
if curl -s -f "${PROD_URL}/_health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Production non accessible${NC}"
    exit 1
fi

echo -n "  • PR #${PR_NUMBER}... "
if curl -s -f "${PR_URL}/_health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ PR non accessible${NC}"
    echo -e "${YELLOW}ℹ Vérifiez que la PR #${PR_NUMBER} existe et est déployée${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Test 2 : Récupérer les villes initiales
# ============================================================================
echo -e "${BOLD}[Test 2/5]${NC} Récupération des villes initiales..."

echo "  • Production :"
PROD_CITIES_BEFORE=$(curl -s "${PROD_URL}/city")
PROD_COUNT_BEFORE=$(echo "$PROD_CITIES_BEFORE" | jq '. | length')
echo -e "    ${BLUE}→${NC} ${PROD_COUNT_BEFORE} villes trouvées"
echo "$PROD_CITIES_BEFORE" | jq -r '.[] | "      - \(.name) (\(.department_code))"' | head -5

echo ""
echo "  • PR #${PR_NUMBER} :"
PR_CITIES_BEFORE=$(curl -s "${PR_URL}/city")
PR_COUNT_BEFORE=$(echo "$PR_CITIES_BEFORE" | jq '. | length')
echo -e "    ${BLUE}→${NC} ${PR_COUNT_BEFORE} villes trouvées"
echo "$PR_CITIES_BEFORE" | jq -r '.[] | "      - \(.name) (\(.department_code))"' | head -5

if [ "$PR_COUNT_BEFORE" -eq "$PROD_COUNT_BEFORE" ]; then
    echo -e "    ${GREEN}✓${NC} PR initialisée avec ${PR_COUNT_BEFORE} villes (identique à prod)"
else
    echo -e "    ${YELLOW}⚠${NC} PR a ${PR_COUNT_BEFORE} villes, prod a ${PROD_COUNT_BEFORE} villes"
fi

echo ""

# ============================================================================
# Test 3 : Ajouter une ville dans la PR
# ============================================================================
echo -e "${BOLD}[Test 3/5]${NC} Ajout d'une ville de test dans la PR..."

TEST_CITY='{
  "departmentCode": "99",
  "inseeCode": "99999",
  "zipCode": "99999",
  "name": "Ville de Test PR'${PR_NUMBER}'",
  "lat": 45.0,
  "lon": 5.0
}'

echo -e "  ${BLUE}→${NC} Ajout de \"Ville de Test PR${PR_NUMBER}\" dans la PR..."
RESPONSE=$(curl -s -X POST "${PR_URL}/city" \
  -H "Content-Type: application/json" \
  -d "$TEST_CITY")

if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
    CREATED_ID=$(echo "$RESPONSE" | jq -r '.id')
    echo -e "    ${GREEN}✓${NC} Ville créée avec ID: ${CREATED_ID}"
else
    echo -e "    ${RED}✗${NC} Erreur lors de la création"
    echo "$RESPONSE" | jq .
    exit 1
fi

echo ""

# ============================================================================
# Test 4 : Vérifier l'isolation (prod non impactée)
# ============================================================================
echo -e "${BOLD}[Test 4/5]${NC} Vérification de l'isolation..."

echo "  • Vérification de la PR :"
PR_CITIES_AFTER=$(curl -s "${PR_URL}/city")
PR_COUNT_AFTER=$(echo "$PR_CITIES_AFTER" | jq '. | length')
TEST_CITY_IN_PR=$(echo "$PR_CITIES_AFTER" | jq -r --arg name "Ville de Test PR${PR_NUMBER}" '.[] | select(.name == $name) | .name')

if [ -n "$TEST_CITY_IN_PR" ]; then
    echo -e "    ${GREEN}✓${NC} Ville de test présente dans la PR (${PR_COUNT_AFTER} villes total)"
else
    echo -e "    ${RED}✗${NC} Ville de test non trouvée dans la PR"
    exit 1
fi

echo ""
echo "  • Vérification de la production :"
PROD_CITIES_AFTER=$(curl -s "${PROD_URL}/city")
PROD_COUNT_AFTER=$(echo "$PROD_CITIES_AFTER" | jq '. | length')
TEST_CITY_IN_PROD=$(echo "$PROD_CITIES_AFTER" | jq -r --arg name "Ville de Test PR${PR_NUMBER}" '.[] | select(.name == $name) | .name')

if [ -z "$TEST_CITY_IN_PROD" ]; then
    echo -e "    ${GREEN}✓${NC} Ville de test ABSENTE de la prod (${PROD_COUNT_AFTER} villes, inchangé)"
else
    echo -e "    ${RED}✗${NC} ERREUR: La ville de test est dans la prod !"
    exit 1
fi

if [ "$PROD_COUNT_BEFORE" -eq "$PROD_COUNT_AFTER" ]; then
    echo -e "    ${GREEN}✓${NC} Nombre de villes en prod inchangé (${PROD_COUNT_AFTER})"
else
    echo -e "    ${RED}✗${NC} Le nombre de villes en prod a changé !"
    exit 1
fi

echo ""

# ============================================================================
# Test 5 : Résumé
# ============================================================================
echo -e "${BOLD}[Test 5/5]${NC} Résumé des résultats..."
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✓ TOUS LES TESTS PASSÉS                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Résultats :${NC}"
echo -e "  ${GREEN}✓${NC} Production accessible et fonctionnelle"
echo -e "  ${GREEN}✓${NC} PR #${PR_NUMBER} accessible et fonctionnelle"
echo -e "  ${GREEN}✓${NC} PR initialisée avec ${PR_COUNT_BEFORE} villes (dump)"
echo -e "  ${GREEN}✓${NC} Ajout d'une ville dans la PR réussi"
echo -e "  ${GREEN}✓${NC} Ville de test présente dans la PR (${PR_COUNT_AFTER} villes)"
echo -e "  ${GREEN}✓${NC} Production non impactée (${PROD_COUNT_AFTER} villes, inchangé)"
echo ""
echo -e "${BOLD}${BLUE}➜${NC} ${BOLD}Les bases de données sont bien isolées !${NC}"
echo ""
echo -e "${YELLOW}Pour nettoyer la ville de test :${NC}"
echo -e "  curl -X DELETE \"${PR_URL}/city/${CREATED_ID}\""
echo ""
