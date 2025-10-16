# 📊 Workflow de gestion de la base de données

## Architecture

- **Production (springcity-static)** : Base de données PostgreSQL persistante avec PVC
- **Environnements PR (éphémères)** : Initialisés avec un dump de la prod

## 🔄 Mettre à jour le dump pour les PRs

### 1. Dumper la base de prod

```bash
./scripts/dump-prod-db.sh
```

Ce script va :
- Se connecter au pod PostgreSQL de production
- Extraire les données avec `pg_dump`
- Sauvegarder dans `deploy/helm/springcity/init-data/dump.sql`

### 2. Vérifier le dump

```bash
cat deploy/helm/springcity/init-data/dump.sql
```

### 3. Commiter et pusher

```bash
git add deploy/helm/springcity/init-data/dump.sql
git commit -m "chore: update prod DB dump for ephemeral envs"
git push
```

### 4. Les nouvelles PRs utiliseront automatiquement le dump

Quand une PR est créée :
1. GitHub Actions build l'image Docker
2. ArgoCD crée un namespace `springcity-pr-XX`
3. Une base PostgreSQL est créée
4. Le dump est chargé automatiquement via ConfigMap
5. L'application démarre avec les données de prod

## 📝 Configuration

### Production (values-static.yaml)
```yaml
postgres:
  enabled: true
  storage: 1Gi
  initFromDump: false  # Utilise le script d'init standard
```

### Environnements PR (values-pr-template.yaml)
```yaml
postgres:
  enabled: true
  storage: 1Gi
  initFromDump: true   # Utilise le dump de prod
```

## 🔧 Modification manuelle du dump

Si vous voulez modifier manuellement le dump :

1. Éditer `deploy/helm/springcity/init-data/dump.sql`
2. Ajouter/modifier les données SQL
3. Commiter et pusher

## ⚠️ Important

- Le dump est chargé **uniquement lors de la création** de la base de données
- Si le pod PostgreSQL redémarre, les données en mémoire sont perdues (environnements éphémères)
- Pour la prod, les données sont persistées dans un PVC

## 🧪 Tester localement

```bash
# Tester le rendu Helm avec le dump
helm template test deploy/helm/springcity \
  -f deploy/helm/overlays/values-pr-template.yaml \
  --set fullnameOverride=pr-test \
  --set image.tag=pr-99 | grep -A 30 "postgres-data"
```

## 🚀 Workflow complet

1. **Développeur crée une PR** → GitHub Actions build l'image
2. **ArgoCD détecte la PR** → Crée l'environnement
3. **PostgreSQL démarre** → Charge le dump automatiquement
4. **App démarre** → Connectée à la DB avec données de prod
5. **PR fermée** → Environnement supprimé automatiquement

## 📊 Avantages

✅ **Données réalistes** : Les PRs testent avec des données de production  
✅ **Isolation** : Chaque PR a sa propre base de données  
✅ **Automatique** : Aucune action manuelle requise  
✅ **Léger** : Dump SQL versionné dans Git  
✅ **Reproductible** : Chaque PR démarre avec les mêmes données  
