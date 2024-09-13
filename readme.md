
# Projet de Réhabilitation d'Infrastructure

Ce projet consiste à reprendre et réparer une infrastructure existante qui comportait un frontend, un backend, une base de données, et un système de monitoring. Après avoir analysé et corrigé les problèmes, l'infrastructure a été réorganisée avec des technologies modernes et des composants séparés pour une meilleure maintenabilité et évolutivité.

## Infrastructure Actuelle

### 1. Frontend

- **Technologie** : React
- **Description** : Le frontend de l'application a été reconstruit en utilisant React pour une meilleure interactivité et performance. Les composants sont maintenant plus modulaires et maintenables.

### 2. Backend

- **Technologie** : Express (Node.js)
- **Description** : Le backend a été refait en utilisant Express, un framework minimaliste pour Node.js, permettant de créer des APIs performantes et évolutives. Toutes les routes et la logique métier ont été réorganisées pour optimiser les performances et la sécurité.

### 3. Base de Données

- **CMS** : October CMS
- **Description** : October CMS est utilisé pour la gestion de contenu. Il est couplé avec une base de données qui permet de stocker et de gérer les données de manière efficace. La structure des données a été repensée pour une meilleure cohérence et des requêtes plus rapides.

### 4. Monitoring

- **Technologies** : Prometheus et Grafana
- **Description** : Un système de monitoring a été mis en place pour surveiller les performances et la santé de l'infrastructure. Prometheus est utilisé pour la collecte des métriques, et Grafana pour la visualisation de ces métriques. Cela permet d'identifier rapidement les problèmes et d'optimiser les ressources.

### 5. Gestion du Code Source

- **Serveur GitLab**
- **Description** : Le code source est maintenant versionné et géré via un serveur GitLab dédié. Cela permet de collaborer efficacement, d'assurer le contrôle de version et de déployer des pipelines CI/CD.

## Architecture de l'Infrastructure

L'infrastructure est divisée en plusieurs composants, chacun étant hébergé sur des machines séparées pour des raisons de sécurité et de performance :

- **Machine 1** : Frontend (React)
- **Machine 2** : Backend (Express)
- **Machine 3** : Base de données et October CMS
- **Machine 4** : Monitoring (Prometheus et Grafana)
- **Machine 5** : Serveur GitLab

## Déploiement et Maintenance

L'infrastructure est conçue pour être facilement déployée et maintenue. Chaque composant peut être mis à jour indépendamment sans affecter les autres services. Des scripts d'automatisation sont fournis pour faciliter les déploiements et les mises à jour.

## Conclusion

Ce projet a permis de moderniser une infrastructure existante en utilisant des technologies modernes et des bonnes pratiques de développement. L'utilisation de composants séparés améliore la sécurité, la performance, et la maintenabilité de l'ensemble du système.

## Contribution

Les contributions sont les bienvenues. Merci de soumettre vos pull requests sur le serveur GitLab et de suivre les guides de contribution.
