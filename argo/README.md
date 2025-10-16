# Configuration ArgoCD avec ApplicationSet

Ce dossier contient la configuration GitOps pour déployer SpringCity avec :
- **1 environnement statique** (production) toujours actif
- **N environnements éphémères** automatiquement créés/supprimés pour chaque PR

## Architecture

```
GitHub Repository
        │
        ├── Push sur main → Image :main → Env statique
        └── PR ouverte    → Image :pr-X → Env éphémère pr-X
                            PR fermée → Env supprimé automatiquement
```

## Fichiers

- **`project.yaml`** : Projet ArgoCD SpringCity avec permissions
- **`app-static.yaml`** : Application pour l'environnement statique
- **`appset-prs.yaml`** : ApplicationSet qui gère automatiquement les PRs

## Installation

### 1. Installer ArgoCD

```bash
# Créer le namespace
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que tous les pods soient prêts
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s
```

### 2. Accéder à l'interface ArgoCD

```bash
# Port-forward vers l'UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupérer le mot de passe
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

# Ouvrir https://localhost:8080
# Username: admin
# Password: (celui affiché ci-dessus)
```

### 3. Créer un token GitHub (optionnel mais recommandé)

Pour éviter le rate-limit de l'API GitHub :

```bash
# Créer un Personal Access Token sur GitHub avec le scope 'repo'
# Puis créer le secret dans ArgoCD :
kubectl -n argocd create secret generic github-token \
  --from-literal=token=ghp_VOTRE_TOKEN_GITHUB
```

### 4. Appliquer les manifests ArgoCD

```bash
# Depuis la racine du projet
kubectl apply -f argo/project.yaml
kubectl apply -f argo/app-static.yaml
kubectl apply -f argo/appset-prs.yaml
```

## Vérification

### Environnement statique

```bash
# Voir l'application
argocd app get springcity-static

# Voir les ressources Kubernetes
kubectl get all -n springcity-static

# Accéder à l'application (local)
# URL : http://springcity.127.0.0.1.nip.io (avec Traefik)
# OU port-forward :
kubectl port-forward -n springcity-static svc/springcity-static 2022:2022
curl http://localhost:2022/_health
```

### Environnements éphémères (PRs)

Lorsqu'une PR est ouverte :

1. **ApplicationSet détecte la PR** (polling toutes les 60s)
2. **ArgoCD crée automatiquement** :
   - Application : `springcity-pr-<number>`
   - Namespace : `springcity-pr-<number>`
   - Tous les ressources (Deployment, Service, PVC, etc.)
3. **URL accessible** : `http://pr-<number>.127.0.0.1.nip.io`

```bash
# Lister toutes les applications (statique + PRs)
argocd app list

# Voir une PR spécifique
argocd app get springcity-pr-42

# Voir les ressources
kubectl get all -n springcity-pr-42

# Accéder à l'application
# URL : http://pr-42.127.0.0.1.nip.io
# OU port-forward :
kubectl port-forward -n springcity-pr-42 svc/pr-42 9999:2022
curl http://localhost:9999/_health
```

### Nettoyage automatique

Lorsqu'une PR est fermée ou mergée :
- **ApplicationSet supprime l'Application ArgoCD**
- **ArgoCD prune toutes les ressources** (pods, services, PVC, namespace)
- **Aucune action manuelle nécessaire** ✅

## Workflow complet

### Pour l'environnement statique

```
1. Push sur main
2. GitHub Actions build l'image :main
3. ArgoCD détecte le changement (auto-sync)
4. ArgoCD déploie la nouvelle version
```

### Pour les environnements éphémères

```
1. Ouvrir une PR
2. GitHub Actions build l'image :pr-X
3. ApplicationSet détecte la PR
4. ArgoCD crée l'application + namespace
5. ArgoCD déploie l'image :pr-X
6. URL accessible : http://pr-X.127.0.0.1.nip.io

7. Push sur la branche de la PR
8. GitHub Actions rebuild l'image :pr-X (même tag)
9. ArgoCD détecte le changement (imagePullPolicy: Always)
10. ArgoCD redéploie avec la nouvelle image

11. Fermer/merger la PR
12. ApplicationSet supprime l'application
13. ArgoCD nettoie toutes les ressources
```

## Configuration

### Changer le dépôt GitHub

Si vous forkez le projet, modifiez dans **tous les fichiers** :

```yaml
# argo/project.yaml
sourceRepos:
  - https://github.com/VOTRE-USERNAME/cicd-project.git

# argo/app-static.yaml
source:
  repoURL: https://github.com/VOTRE-USERNAME/cicd-project.git

# argo/appset-prs.yaml
generators:
  - pullRequest:
      github:
        owner: VOTRE-USERNAME
        repo: cicd-project
source:
  repoURL: https://github.com/VOTRE-USERNAME/cicd-project.git
```

### Changer l'image Docker

Si vous changez le nom de l'image, modifiez :

```yaml
# deploy/helm/overlays/values-static.yaml
image:
  repository: VOTRE-USERNAME/VOTRE-IMAGE

# argo/appset-prs.yaml (dans la section values)
image:
  repository: VOTRE-USERNAME/VOTRE-IMAGE
```

## Commandes utiles

```bash
# Lister toutes les applications
argocd app list

# Forcer la synchronisation
argocd app sync springcity-static
argocd app sync springcity-pr-42

# Voir les différences Git vs Cluster
argocd app diff springcity-static

# Voir l'historique de déploiement
argocd app history springcity-static

# Voir les logs d'une application
argocd app logs springcity-static

# Supprimer manuellement une application PR (si besoin)
argocd app delete springcity-pr-42 --yes --cascade

# Voir les ApplicationSets
kubectl get applicationset -n argocd

# Voir les détails d'un ApplicationSet
kubectl describe applicationset springcity-prs -n argocd
```

## Dépannage

### ApplicationSet ne détecte pas les PRs

```bash
# Vérifier les logs de l'applicationset-controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller -f

# Vérifier que le token GitHub est configuré
kubectl get secret -n argocd github-token

# Vérifier le rate-limit GitHub (si pas de token)
# https://api.github.com/rate_limit
```

### Une PR n'a pas créé d'application

```bash
# Vérifier l'ApplicationSet
kubectl get applicationset -n argocd springcity-prs -o yaml

# Voir les applications générées
kubectl get application -n argocd -l pr-number

# Forcer un refresh (ApplicationSet repolling)
kubectl annotate applicationset -n argocd springcity-prs \
  argocd.argoproj.io/refresh=normal
```

### L'image Docker n'est pas mise à jour

Vérifier que :
- GitHub Actions a bien pushé l'image avec le bon tag (:pr-X)
- `imagePullPolicy: Always` est bien défini
- Le pod a été redémarré après le push

```bash
# Forcer un redémarrage
kubectl rollout restart -n springcity-pr-42 deployment/pr-42
```

## Différences avec l'ancienne approche

### Avant (workflows GitHub Actions)

❌ Workflows manuels pour créer/supprimer les applications  
❌ Besoin d'un serveur ArgoCD accessible depuis Internet  
❌ Tokens ArgoCD dans les secrets GitHub  
❌ Plus complexe à maintenir

### Maintenant (ApplicationSet)

✅ Détection automatique des PRs par ArgoCD  
✅ Pas besoin que ArgoCD soit accessible depuis Internet  
✅ Moins de secrets à gérer  
✅ Configuration déclarative pure (GitOps)  
✅ Plus simple et plus robuste

## Ressources

- [Documentation ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [PullRequest Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/)
- [Helm Values avec ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
