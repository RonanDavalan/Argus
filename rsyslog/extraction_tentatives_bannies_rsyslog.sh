#!/bin/bash

# -------------------------------------------------
# Nom du développeur : Ronan DAVALAN
# Date : 05/08/2024
# Licence : MIT
# Usage : Ce script comptabilise les adresses IP bannies du jour précédent pour chaque filtre de Fail2ban.
#
# Assistants IA utilisés au cours du développement :
# - Perplexity AI (perplexity.ai)
# - ChatGPT (openai.com)
# - Diverses IA
# -------------------------------------------------

# Répertoire de stockage des adresses IP bannies par année
repertoire_destination="/home/nom_utilisateur/$(date -d yesterday +%Y)"
utilisateur="nom_utilisateur"
groupe="nom_utilisateur"

# Exécution de la commande pour rechercher et enregistrer les adresses IP bannies du jour précédent
grep '^\[.*\]' /etc/fail2ban/jail.local | grep -v '\[DEFAULT\]' | \
awk -F'[][]' '{print "zgrep '\''Ban'\'' /var/log/fail2ban.log* | zgrep -v '\''Restore Ban'\'' | grep '\''\\[" $2 "\\]'\'' | awk '\''{print $1}'\'' | cut -d \":\" -f 2 | grep \"$(date -d yesterday '+%Y-%m-%d')\" | sort | uniq -c >> $repertoire_destination/ip_bannies_" $2 "_$(date +%Y).txt && chmod 600 $repertoire_destination/ip_bannies_" $2 "_$(date +%Y).txt && chown $utilisateur:$groupe $repertoire_destination/ip_bannies_" $2 "_$(date +%Y).txt"}' | while read -r commande; do eval "$commande"; done

