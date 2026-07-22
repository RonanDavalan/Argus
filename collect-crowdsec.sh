#!/bin/bash
# collect-crowdsec.sh — counts alerts decided by CrowdSec, per scenario, from
# `cscli alerts list -o json`. Optional: a no-op, silent, successful exit if
# CrowdSec (or jq) is absent — same modularity as collect-fail2ban.sh, both
# can run side by side without conflict if both tools are installed.
#
# Validated 22/07/2026 against a real CrowdSec instance (Davalan-vps,
# v1.7.8, real ssh-bf/ssh-slow-bf alerts). First version of this script
# assumed "scenario" was a top-level field on each alert — wrong: it lives
# under decisions[], one alert can carry more than one decision. Fixed and
# re-verified against real JSON before this line was written.
#
# Argus does not re-decide what counts as an attack here: it counts what
# CrowdSec already decided, same rationale as the Fail2Ban backend.
#
# Run once daily (cron), processes the previous full day. Output: one flat
# text file per year per scenario (`ip_ban_<scenario>_<year>.txt`), one line
# per (date, hour) bucket: "<count> <YYYY-MM-DDTHH>". Idempotent per scenario.
set -Eeuo pipefail

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"

# CrowdSec ou jq absents : sortie silencieuse, succès. Modularité du backend
# jail — Argus fonctionne sans, collect-ssh.sh suffit.
if ! command -v cscli >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
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

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# --since 2d : fenêtre large pour couvrir la journée complète de la veille
# quelle que soit l'heure d'exécution du cron ; filtrage exact sur la date
# fait ensuite en jq. Le scénario (ex. "crowdsecurity/ssh-bf") vit sous
# decisions[], pas au premier niveau de l'alerte — une alerte peut porter
# plusieurs décisions, chacune comptée séparément, à l'heure de l'alerte qui
# les porte (les décisions elles-mêmes n'ont pas d'horodatage propre, juste
# une durée). Tronqué à sa partie après "/" pour rester comparable à un nom
# de jail Fail2Ban.
cscli alerts list -o json --since 2d 2>/dev/null \
    | jq -r --arg jour "$YESTERDAY" '
        .[]?
        | select(.created_at != null and (.created_at | startswith($jour)))
        | .created_at as $when
        | .decisions[]?
        | [(.scenario // "inconnu" | split("/") | last), ($when[0:13])]
        | @tsv
    ' 2>/dev/null | sort | uniq -c > "$tmp"
# tmp : "<compte> <scenario> <date>T<heure>"

# ── Battement de vie — voir collect-ssh.sh pour le raisonnement complet.
#    Placé avant la sortie anticipée ci-dessous : c'est justement le jour à
#    zéro alerte que ce fichier doit enregistrer, pas seulement les jours actifs.
heartbeat_dir="$annee_dir/.heartbeat"
heartbeat_file="$heartbeat_dir/crowdsec.txt"
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

for scenario in $(awk '{print $2}' "$tmp" | sort -u); do
    sortie="$annee_dir/ip_ban_${scenario}_${YEAR}.txt"
    if [ -f "$sortie" ] && grep -q "^[[:space:]]*[0-9]\+ ${YESTERDAY}T" "$sortie"; then
        continue
    fi
    awk -v s="$scenario" '$2 == s {print $1, $3}' "$tmp" >> "$sortie"
    chmod 644 "$sortie" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$sortie" 2>/dev/null || true
    fi
done
