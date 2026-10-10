#!/bin/bash
# collect-fail2ban.sh — compte les bannissements décidés par Fail2Ban, par
# jail, depuis fail2ban.log. Optionnel : sortie silencieuse et réussie si
# Fail2Ban n'est pas installé, sans jamais faire échouer l'entrée cron de
# collect-ssh.sh.
#
# Argus ne redécide pas ici ce qui est une attaque : il compte ce que Fail2Ban
# a déjà décidé (lignes « Ban »), hors « Restore Ban » (bannissements
# restaurés au démarrage du service, pas de nouvelles attaques). Même raison
# d'être que le projet autonome depuis 2024.
#
# Lancé une fois par jour (cron), traite la veille entière. Sortie : un
# fichier texte plat par année et par jail (`ip_ban_<jail>_<année>.txt`), une
# ligne par tranche (date, heure) : « <compte> <AAAA-MM-JJTHH> ». Idempotent
# par jail.
set -Eeuo pipefail

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
F2BLOG="${ARGUS_FAIL2BAN_LOG:-/var/log/fail2ban.log}"

# Fail2Ban absent ou non configuré : sortie silencieuse, succès. C'est la
# modularité du backend jail — Argus fonctionne sans, collect-ssh.sh suffit.
if ! command -v fail2ban-client >/dev/null 2>&1 || [ ! -e "$F2BLOG" ]; then
    exit 0
fi

YESTERDAY="$(date -d yesterday '+%Y-%m-%d')"
YEAR="$(date -d yesterday '+%Y')"
annee_dir="$DATA_DIR/$YEAR"
mkdir -p "$annee_dir"
chmod 755 "$annee_dir" 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$DATA_DIR" "$annee_dir" 2>/dev/null || true
fi

# Lecture de fail2ban.log et de ses rotations compressées en un seul passage
# (fail2ban.log timestamp au format ISO — pas de dépendance à la locale,
# contrairement à auth.log). Le nom de la jail est extrait directement de la
# ligne de log ("NOTICE [jail] Ban IP"), pas de /etc/fail2ban/jail.local — le
# journal est la source de vérité, il ne peut pas désynchroniser de la config.
extraire() {
    gawk -v jour="$YESTERDAY" '
        /Restore Ban/ { next }
        {
            if (!match($0, /^([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}):[0-9]{2}:[0-9]{2},[0-9]+ .*NOTICE[ \t]+\[([^]]+)\][ \t]+Ban[ \t]+/, m)) next;
            if (m[1] != jour) next;
            print m[3]" "jour"T"m[2];
        }
    '
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
    for f in "$F2BLOG" "$F2BLOG".*.gz; do
        [ -e "$f" ] || continue
        case "$f" in
            *.gz) zcat "$f" ;;
            *)    cat "$f" ;;
        esac
    done
    # Rotation non compressée (logrotate à compression différée d'un cycle) —
    # cas optionnel. Un `if` structuré, pas `[ ... ] && cat ...` : ce dernier,
    # quand le fichier est absent (rotation à compression immédiate, cas réel
    # rencontré en déploiement), fait échouer sa propre expression — et comme c'est
    # la dernière commande du groupe qui alimente le pipeline, `pipefail` +
    # `set -e` transforment une absence normale en arrêt brutal du script,
    # avant même l'écriture du battement de vie. Trouvé en testant contre une
    # vraie machine, pas en relisant le code.
    if [ -e "$F2BLOG.1" ]; then
        cat "$F2BLOG.1"
    fi
} | extraire | sort | uniq -c > "$tmp"
# tmp : "<compte> <jail> <date>T<heure>"

# ── Battement de vie — voir collect-ssh.sh pour le raisonnement complet.
#    Placé avant la sortie anticipée ci-dessous : c'est justement le jour à
#    zéro ban que ce fichier doit enregistrer, pas seulement les jours actifs.
heartbeat_dir="$annee_dir/.heartbeat"
heartbeat_file="$heartbeat_dir/fail2ban.txt"
mkdir -p "$heartbeat_dir"
if ! { [ -f "$heartbeat_file" ] && grep -q "^${YESTERDAY} " "$heartbeat_file"; }; then
    evenements=0
    [ -s "$tmp" ] && evenements=$(awk '{s+=$1} END{print s+0}' "$tmp")
    echo "$YESTERDAY $evenements" >> "$heartbeat_file"
    chmod 644 "$heartbeat_file" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$heartbeat_dir" "$heartbeat_file" 2>/dev/null || true
    fi
fi

[ -s "$tmp" ] || exit 0

for jail in $(awk '{print $2}' "$tmp" | sort -u); do
    sortie="$annee_dir/ip_ban_${jail}_${YEAR}.txt"
    if [ -f "$sortie" ] && grep -q "^[[:space:]]*[0-9]\+ ${YESTERDAY}T" "$sortie"; then
        continue
    fi
    awk -v j="$jail" '$2 == j {print $1, $3}' "$tmp" >> "$sortie"
    chmod 644 "$sortie" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$sortie" 2>/dev/null || true
    fi
done
