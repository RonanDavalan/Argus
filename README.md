# README pour le suivi des IP bannies avec Fail2Ban

## Introduction
Ce document décrit la mise en place d'un script bash pour compter et enregistrer le nombre d'adresses IP bannies par Fail2Ban sur un serveur. Le script est conçu pour être exécuté quotidiennement et stocke les résultats dans des répertoires organisés par année. L'objectif est de permettre une représentation graphique du nombre d'IP rejetées, sans jamais extraire ni enregistrer les adresses IP elles-mêmes.

## Fonctionnement

1. **Configuration des répertoires** :
   - Le script utilise un répertoire de destination pour stocker les fichiers de logs, organisé par année.
   - Le chemin du répertoire est défini dans la variable `repertoire_destination`.
   - Si le répertoire de l'année n'existe pas, il est créé.

2. **Gestion des utilisateurs** :
   - Les variables `utilisateur` et `groupe` définissent les propriétaires des fichiers générés.
   - Les permissions des fichiers générés sont définies à 600 (lecture/écriture pour le propriétaire uniquement).

3. **Comptage des IP bannies** :
   - Le script parcourt le fichier `/etc/fail2ban/jail.local` pour identifier les jails configurés.
   - Pour chaque jail, il compte le nombre d'adresses IP bannies le jour précédent à partir des logs de Fail2Ban.
   - Les résultats (date et nombre d'IP bannies) sont enregistrés dans des fichiers séparés pour chaque jail. Le format du nom de fichier est : `ip_ban_[NOM_DU_JAIL]_[ANNÉE].txt`.

4. **Sécurité** :
   - Les permissions des fichiers générés sont définies à 600 (lecture/écriture pour le propriétaire uniquement).
   - Les fichiers sont également attribués à l'utilisateur et au groupe spécifiés.

## Configuration
- Le script utilise les configurations existantes de Fail2Ban, notamment le fichier `/etc/fail2ban/jail.local`.
- Assurez-vous que les chemins des logs Fail2Ban sont corrects (`/var/log/fail2ban.log*`).

## Automatisation
Il est recommandé de configurer une tâche cron pour exécuter ce script quotidiennement, idéalement après minuit pour capturer les données du jour précédent.

## Exemple de tâche cron
Pour automatiser l'exécution du script, ajoutez la ligne suivante à votre crontab :

0 1 * * * /chemin/vers/votre/script.sh

Cela exécutera le script tous les jours à 1h00 du matin.

## Maintenance
Vérifiez régulièrement les fichiers générés pour vous assurer que les données sont correctement enregistrées et que l'espace disque est suffisant.
