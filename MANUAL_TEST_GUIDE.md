# 🧪 Guide de test manuel - Isolation des bases de données

## 🎯 Objectif

Vérifier que les environnements PR sont isolés de la production :
- ✅ Les PRs démarrent avec le dump de prod
- ✅ Les modifications dans une PR n'affectent pas la prod
- ✅ Chaque PR a sa propre base de données

## 🚀 Test automatisé (Recommandé)

```bash
# Lancer le test pour la PR #12
./test-db-isolation.sh 12

# Ou pour une autre PR
./test-db-isolation.sh 10
```

Le script va automatiquement :
1. Vérifier l'accès aux environnements
2. Lister les villes initiales
3. Ajouter une ville de test dans la PR
4. Vérifier que la prod n'est pas impactée
5. Afficher un rapport complet

## 📝 Test manuel (Étape par étape)

### Configuration

Déterminez vos URLs :

```bash
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n1)
echo "Production : http://springcity-static.${SERVER_IP}.nip.io"
echo "PR #12     : http://pr-12.${SERVER_IP}.nip.io"
```

### Étape 1 : Vérifier l'accessibilité

```bash
# Production
curl http://springcity-static.${SERVER_IP}.nip.io/_health

# PR
curl http://pr-12.${SERVER_IP}.nip.io/_health
```

✅ Les deux doivent retourner `HTTP 204 No Content`

### Étape 2 : Lister les villes initiales

**Production :**
```bash
curl http://springcity-static.${SERVER_IP}.nip.io/city | jq .
```

**PR :**
```bash
curl http://pr-12.${SERVER_IP}.nip.io/city | jq .
```

✅ Les deux environnements doivent avoir les mêmes villes au départ (dump identique)

### Étape 3 : Ajouter une ville dans la PR

```bash
curl -X POST http://pr-12.${SERVER_IP}.nip.io/city \
  -H "Content-Type: application/json" \
  -d '{
    "departmentCode": "99",
    "inseeCode": "99999",
    "zipCode": "99999",
    "name": "Ville de Test",
    "lat": 45.0,
    "lon": 5.0
  }'
```

✅ Vous devez recevoir une réponse avec un `id` :
```json
{
  "id": 4,
  "departmentCode": "99",
  "inseeCode": "99999",
  "zipCode": "99999",
  "name": "Ville de Test",
  "lat": 45.0,
  "lon": 5.0
}
```

### Étape 4 : Vérifier l'isolation

**Vérifier que la ville est dans la PR :**
```bash
curl http://pr-12.${SERVER_IP}.nip.io/city | jq '.[] | select(.name == "Ville de Test")'
```

✅ La ville doit être présente

**Vérifier que la ville N'EST PAS dans la prod :**
```bash
curl http://springcity-static.${SERVER_IP}.nip.io/city | jq '.[] | select(.name == "Ville de Test")'
```

✅ Ne doit rien retourner (la prod n'est pas affectée)

**Compter les villes :**
```bash
# Production
curl -s http://springcity-static.${SERVER_IP}.nip.io/city | jq '. | length'

# PR
curl -s http://pr-12.${SERVER_IP}.nip.io/city | jq '. | length'
```

✅ La PR doit avoir 1 ville de plus que la prod

### Étape 5 : Nettoyer (optionnel)

Si vous voulez supprimer la ville de test :

```bash
# Récupérer l'ID de la ville
CITY_ID=$(curl -s http://pr-12.${SERVER_IP}.nip.io/city | jq -r '.[] | select(.name == "Ville de Test") | .id')

# Supprimer (si endpoint DELETE existe)
curl -X DELETE http://pr-12.${SERVER_IP}.nip.io/city/${CITY_ID}
```

## 🐛 Dépannage

### "Connection refused"

```bash
# Vérifier que les pods tournent
kubectl get pods -n springcity-static
kubectl get pods -n springcity-pr-12

# Vérifier les services
kubectl get svc -n springcity-static
kubectl get svc -n springcity-pr-12

# Vérifier les ingress
kubectl get ingress -A
```

### "jq: command not found"

Installez jq :
```bash
sudo apt install jq
```

Ou faites sans jq (réponse brute) :
```bash
curl http://pr-12.${SERVER_IP}.nip.io/city
```

### Les deux environnements ont des villes différentes au départ

C'est normal si :
- La prod a été modifiée depuis la création du dump
- Le dump n'a pas été mis à jour

Pour synchroniser :
```bash
# Extraire les données de prod
kubectl exec -n springcity-static $(kubectl get pod -n springcity-static -l app=postgres -o jsonpath='{.items[0].metadata.name}') \
  -- pg_dump -U user -d city_api --clean --if-exists --no-owner --no-acl \
  > deploy/helm/springcity/init-data/dump.sql

# Commiter
git add deploy/helm/springcity/init-data/dump.sql
git commit -m "chore: update DB dump from production"
git push

# Les nouvelles PRs utiliseront le nouveau dump
```

## ✅ Critères de réussite

- ✅ **Production accessible** : `/_health` retourne 204
- ✅ **PR accessible** : `/_health` retourne 204
- ✅ **Dump chargé** : La PR a les mêmes villes initiales que la prod
- ✅ **Ajout réussi** : Une ville peut être créée dans la PR
- ✅ **Isolation confirmée** : La ville créée dans la PR n'apparaît PAS dans la prod
- ✅ **Comptage correct** : PR a +1 ville, prod inchangée

## 📊 Résultat attendu

```
┌─────────────────────────────────────────┐
│  PROD                    PR #12         │
├─────────────────────────────────────────┤
│  3 villes (dump)         3 villes       │
│                          + Ville Test   │
│  = 3 villes              = 4 villes     │
│                                         │
│  ✓ Pas d'impact          ✓ Isolée      │
└─────────────────────────────────────────┘
```

## 🎯 Points à retenir

1. **Les PRs sont éphémères** : Si le pod PostgreSQL redémarre, les données ajoutées sont perdues
2. **La prod est persistante** : Les données sont stockées dans un PVC
3. **Le dump est statique** : Il faut le mettre à jour manuellement quand la prod évolue
4. **Chaque PR est isolée** : Elles ne partagent rien entre elles ni avec la prod
