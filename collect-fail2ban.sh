#!/bin/bash
# collect-fail2ban.sh — counts bans decided by Fail2Ban, per jail, from
# fail2ban.log. Optional: a no-op, silent, successful exit if Fail2Ban is not
# installed — this script never causes collect-ssh.sh's cron entry to fail.
#
# Argus does not re-decide what counts as an attack here: it counts what
# Fail2Ban already decided ("Ban" lines), excluding "Restore Ban" (bans
# restored at service start, not new attacks). Same rationale as the
# standalone project since 2024.
#
# Run once daily (cron), processes the previous full day. Output: one flat
# text file per year per jail (`ip_ban_<jail>_<year>.txt`), one line per
# (date, hour) bucket: "<count> <YYYY-MM-DDTHH>". Idempotent per jail.
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
    [ -e "$F2BLOG.1" ] && cat "$F2BLOG.1"
} | extraire | sort | uniq -c > "$tmp"
# tmp : "<compte> <jail> <date>T<heure>"

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
