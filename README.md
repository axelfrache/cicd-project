# SpringCity - API Spring Boot avec K3s, Prometheus et Grafana

[![CI](https://github.com/axelfrache/cicd-project/actions/workflows/ci.yml/badge.svg)](https://github.com/axelfrache/cicd-project/actions/workflows/ci.yml)

## Présentation

SpringCity est une API REST développée avec Spring Boot permettant de gérer des informations sur des villes françaises. Ce projet démontre la mise en place d'une architecture complète incluant :

- Développement d'une API REST avec Spring Boot et Kotlin
- Stockage des données dans PostgreSQL
- Déploiement sur Kubernetes (K3s) via Helm
- Monitoring avec Prometheus et Grafana
- Intégration continue avec GitHub Actions

## Fonctionnalités

- Création et récupération d'informations sur des villes
- Exposition de métriques pour Prometheus via Spring Boot Actuator
- Monitoring complet de l'application (performances, santé, métriques métier)
- Déploiement automatisé via Helm sur K3s

## Technologies utilisées

- **Backend** : Spring Boot, Kotlin
- **Base de données** : PostgreSQL
- **Conteneurisation** : Docker, Docker Compose
- **Orchestration** : Kubernetes (K3s), Helm
- **Monitoring** : Prometheus, Grafana
- **CI/CD** : GitHub Actions

## Documentation

Pour une documentation détaillée de l'implémentation, veuillez consulter le [rapport complet](DO3-FRACHE-DESPAUX-SOULET%20Rapport%20CI_CD.pdf).

## Installation

### Prérequis

- Docker et Docker Compose
- K3s (pour le déploiement Kubernetes)
- kubectl
- Helm

### Démarrage rapide avec Docker Compose

```bash
# Cloner le dépôt
git clone https://github.com/axelfrache/cicd-project.git
cd cicd-project

# Lancer l'application avec Docker Compose
docker-compose up -d
```

L'application sera accessible à l'adresse : http://localhost:2022

### Déploiement sur K3s

```bash
# Installation de K3s
curl -sfL https://get.k3s.io | sh -

# Déploiement avec Helm
helm install springcity ./deploy/helm/springcity
```

L'application sera accessible à l'adresse : http://localhost:32022

## Monitoring

### Prometheus

Prometheus est configuré pour collecter les métriques de l'application Spring Boot via l'endpoint `/actuator/prometheus`.

Interface web : http://localhost:9090

### Grafana

Grafana est configuré pour visualiser les métriques collectées par Prometheus.

- Interface web : http://localhost:3000
- Identifiants par défaut : admin/admin
- Un dashboard préconfiguré est disponible pour surveiller :
  - Performances des API
  - Métriques JVM
  - Métriques système
  - Métriques métier

## Endpoints API

- `POST /city` : Créer une nouvelle ville
- `GET /city` : Récupérer la liste des villes
- `GET /_health` : Vérifier l'état de santé de l'application
- `GET /actuator/prometheus` : Exposer les métriques pour Prometheus

## Tests

```bash
# Exécuter les tests
mvn test
```

## Variables d'environnement

L'application utilise les variables d'environnement suivantes :

- `CITY_API_ADDR` : Adresse d'écoute du serveur HTTP (défaut : 127.0.0.1)
- `CITY_API_PORT` : Port d'écoute du serveur HTTP (défaut : 2022)
- `CITY_API_DB_URL` : URL de connexion à la base de données
- `CITY_API_DB_USER` : Nom d'utilisateur pour la base de données
- `CITY_API_DB_PWD` : Mot de passe pour la base de données

## Auteurs

- Axel FRACHE
- Noa DESPAUX
- Liam SOULET