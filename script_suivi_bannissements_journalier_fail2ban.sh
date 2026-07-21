#!/bin/bash

# Répertoire de stockage des adresses IP bannies par année
# Le premier janvier ça serait dommage de mettre à jours les fichiers au 31 décembre dans le nouveau répertoire année, il faudra donc écrire dans celui de la veille
repertoire_destination="/var/www/vhosts/example.org/bannies/$(date -d yesterday +%Y)"
utilisateur="utilisateur_web"
groupe="groupe_web"

# Exécution de la commande pour rechercher et enregistrer les adresses IP bannies la première fois
#grep '^\[.*\]' /etc/fail2ban/jail.local | grep -v '\[DEFAULT\]' | awk -F'[][]' '{print "zgrep '\''Ban'\'' /var/log/fail2ban.log* | zgrep -v '\''Restore Ban'\'' | grep '\''\\[" $2 "\\]'\'' | awk '\''{print $1}'\'' | cut -d \":\" -f 2 | sort | uniq -c > $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && chmod 600 $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && chown $utilisateur:$groupe $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt"}' | while read -r commande; do eval "$commande"; done

# Exécution de la commande pour rechercher et enregistrer les adresses IP bannies du jour précédent
grep '^\[.*\]' /etc/fail2ban/jail.local | grep -v '\[DEFAULT\]' | \
awk -F'[][]' '{print "zgrep '\''Ban'\'' /var/log/fail2ban.log* | zgrep -v '\''Restore Ban'\'' | grep '\''\\[" $2 "\\]'\'' | awk '\''{print $1}'\'' | cut -d \":\" -f 2 | grep \"$(date -d yesterday '+%Y-%m-%d')\" | sort | uniq -c >> $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && chmod 600 $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt && chown $utilisateur:$groupe $repertoire_destination/ip_ban_" $2 "_$(date +%Y).txt"}' | while read -r commande; do eval "$commande"; done

