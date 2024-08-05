# README pour les Scripts d'Analyse Fail2Ban

## Introduction
Ce document décrit la mise en place de scripts pour compter et reporter sur un graphique généré tous les jours avec Gnuplot les tentatives de connexion repérées conduisant au bannissement d'adresses IP par Fail2Ban sur un serveur. Fail2Ban protège le serveur contre les attaques par force brute en bannissant les adresses IP malveillantes.

## Scripts
Deux scripts sont utilisés :
1. Un script bash pour extraire les données des logs de Fail2Ban.
2. Un script Gnuplot pour générer un graphique à partir des données extraites.

## Suivi des Adresses IP Bannies
Le script bash extrait et enregistre les adresses IP bannies chaque jour. Les résultats sont stockés dans des répertoires organisés par année.

## Automatisation
Des tâches cron peuvent être configurées pour exécuter automatiquement les scripts de suivi et de génération de rapports quotidiens.

## Génération de Graphiques
Le script Gnuplot génère un graphique quotidien montrant le nombre d'adresses IP bannies par jour pour chaque service configuré dans Fail2Ban.

## Conclusion
Ces scripts permettent une représentation visuelle des différentes tentatives de connexion filtrées par Fail2Ban, sans modifier la configuration de Fail2Ban elle-même.

