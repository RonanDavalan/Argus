#!/bin/bash

# -------------------------------------------------
# Nom du développeur : Ronan DAVALAN
# Date : 05/08/2024
# Licence : MIT
# Usage : Ce script recherche et enregistre les adresses IP bannies du jour précédent à partir des journaux fail2ban.
#
# Assistants IA utilisés au cours du développement :
# - Perplexity AI (perplexity.ai)
# - ChatGPT (openai.com)
# - Diverses IA

# -------------------------------------------------
# Définition des variables
repertoire_destination="/home/user/$(date -d yesterday +%Y)"
utilisateur="user"
groupe="user"

# -------------------------------------------------
# Arrêt du script en cas d'erreur
set -Eeuo pipefail

# -------------------------------------------------
# Recherche et enregistrement des adresses IP bannies du jour précédent
grep '^\[.*\]' /etc/fail2ban/jail.local | grep -v '\[DEFAULT\]' | \
awk -F'[][]' '{
    # Construction de la commande pour chaque service
    print "zgrep '\''Ban'\'' /var/log/fail2ban.log* | \
           zgrep -v '\''Restore Ban'\'' | \
           grep '\''\\[" $2 "\\]'\'' | \
           awk '\''{print $1}'\'' | \
           cut -d \":\" -f 2 | \
           grep \"$(date -d yesterday '+%Y-%m-%d')\" | \
           sort | uniq -c >> $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && \
           chmod 600 $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && \
           chown $utilisateur:$groupe $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt"
}' | while read -r commande
do
    # Exécution de la commande pour chaque service
    eval "$commande"
done
