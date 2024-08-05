# README pour la Configuration de Fail2Ban

## Introduction
Ce document décrit la configuration et le suivi de Fail2Ban sur un serveur géré par Plesk. Fail2Ban protège le serveur contre les attaques par force brute en bannissant les adresses IP malveillantes.

## Configuration
Fail2Ban est installé et configuré sur le serveur. Les règles de configuration se trouvent dans le fichier `/etc/fail2ban/jail.local`.

## Suivi des Adresses IP Bannies
Un système de scripts est mis en place pour extraire et enregistrer les adresses IP bannies chaque jour. Les résultats sont stockés dans des répertoires organisés par année.

## Automatisation
Des tâches cron sont configurées pour exécuter automatiquement les scripts de suivi et de génération de rapports à des intervalles réguliers.

## Journalisation

### Rsyslog
Les événements de Fail2Ban sont enregistrés via **rsyslog**, permettant un suivi et une analyse des tentatives d'accès non autorisées. Les logs sont stockés dans des fichiers accessibles pour consultation.

### Journalctl
Alternativement, il est possible d'utiliser **journalctl** pour consulter les logs de Fail2Ban. Cela permet d'afficher les messages en temps réel et d'effectuer des recherches dans l'historique des journaux.

## Conclusion
Cette configuration de Fail2Ban assure une protection efficace contre les attaques par force brute. Pour toute question ou assistance, veuillez contacter l'administrateur du serveur.

