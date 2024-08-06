#!/bin/bash

# -------------------------------------------------
# Nom du développeur : Ronan DAVALAN
# Date : 05/08/2024
# Licence : MIT
# Usage : Ce script recherche et enregistre les adresses IP bannies du jour précédent à partir des journaux fail2ban.
#
# Assistants IA utilisés au cours du développement :
# 
# - ChatGPT (openai.com)
# - Claude AI (https://claude.ai)
# - Perplexity AI (perplexity.ai)
# - Diverses IA

# -------------------------------------------------
# Définition des variables
REPERTOIRE_DESTINATION="/home/nom_utilisateur/$(date -d yesterday +%Y)"
UTILISATEUR="nom_utilisateur"
GROUPE="nom_groupe"
DATE_LOG=$(date -d yesterday '+%Y-%m-%d')

# -------------------------------------------------
# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# -------------------------------------------------
# Arrêt du script en cas d'erreur
set -Eeuo pipefail

# -------------------------------------------------
# Vérification et création du répertoire de destination si nécessaire
if [ ! -d "$repertoire_destination" ]; then
    mkdir -p "$repertoire_destination"
    log "Répertoire de destination créé : $repertoire_destination"
fi

# -------------------------------------------------
# Recherche et enregistrement des adresses IP bannies du jour précédent
log "Début de l'extraction des données pour la date : $date_log"

grep '^\[.*\]' /etc/fail2ban/jail.local | grep -v '\[DEFAULT\]' | \
awk -F'[][]' '{
    fichier_sortie="'"$repertoire_destination"'/ip_ban_" $2 "_'"$(date +%Y)"'.txt"
    print "zgrep '\''Ban'\'' /var/log/fail2ban.log* | \
           zgrep -v '\''Restore Ban'\'' | \
           grep '\''\\[" $2 "\\]'\'' | \
           awk '\''{print $1}'\'' | \
           cut -d \":\" -f 2 | \
           grep \"'"$date_log"'\" | \
           sort | uniq -c >> " fichier_sortie " && \
           chmod 600 " fichier_sortie " && \
           chown '"$utilisateur:$groupe"' " fichier_sortie
}' | while read -r commande
do
    eval "$commande"
    if [ $? -eq 0 ]; then
        log "Extraction réussie pour le service : $(echo $commande | awk -F'ip_ban_' '{print $2}' | awk -F'_' '{print $1}')"
    else
        log "Erreur lors de l'extraction pour le service : $(echo $commande | awk -F'ip_ban_' '{print $2}' | awk -F'_' '{print $1}')"
    fi
done

log "Fin de l'extraction des données"
