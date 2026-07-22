#!/bin/bash
# argus-doctor.sh — health check for the Argus collection pipeline.
#
# Reads the heartbeat files the collectors write daily (.heartbeat/*.txt,
# added alongside them) to tell a genuinely quiet day apart from a silently
# broken collector. The per-series data files (ssh_direct_*.txt,
# ip_ban_*.txt) never record a zero-event day by design — they cannot
# answer that question on their own, this script exists because of that.
#
# Also checks each source's availability right now (auth.log/journald,
# fail2ban-client, cscli) — a source can be reachable today while
# yesterday's collection still failed for another reason, and vice versa,
# so the two checks are kept separate rather than inferring one from the other.
#
# Does NOT check ARGUS_SSH_THRESHOLD coherence against fail2ban's real
# findtime/maxretry — open question, not resolved yet
# (SPECIFICATIONS/RAISON_ETRE.md, piste "argus-doctor"). Left out on
# purpose rather than guessed.
#
# Run manually or via cron, any time after the collectors (00:05) — reads
# state, writes nothing. Exit 0: nothing to report. Exit 1: at least one
# concern, listed under "À VÉRIFIER" / "TO CHECK".
set -Eeuo pipefail

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
YEAR="${1:-$(date +%Y)}"
AUTHLOG="${ARGUS_AUTHLOG:-/var/log/auth.log}"
UNITE_SSH="${ARGUS_SSHD_UNIT:-ssh}"
F2BLOG="${ARGUS_FAIL2BAN_LOG:-/var/log/fail2ban.log}"
YESTERDAY="$(date -d yesterday '+%Y-%m-%d')"
heartbeat_dir="$DATA_DIR/$YEAR/.heartbeat"

case "${ARGUS_LANG:-en}" in
    fr)
        L_DISPO="Disponibilité des sources"
        L_HISTO="Battements de vie ($YEAR)"
        L_OK="ok"
        L_ABSENT="absente"
        L_JAMAIS="jamais collecté — normal si la source est absente, à surveiller sinon"
        L_AJOUR="à jour, hier :"
        L_EVENEMENTS="événement(s)"
        L_RETARD="dernière confirmation le"
        L_RETARD2="pas d'entrée pour hier"
        L_RIEN="Rien à signaler."
        L_VERIF="À VÉRIFIER"
        ;;
    *)
        L_DISPO="Source availability"
        L_HISTO="Heartbeats ($YEAR)"
        L_OK="ok"
        L_ABSENT="absent"
        L_JAMAIS="never collected — expected if the source is absent, worth watching otherwise"
        L_AJOUR="up to date, yesterday:"
        L_EVENEMENTS="event(s)"
        L_RETARD="last confirmed on"
        L_RETARD2="no entry for yesterday"
        L_RIEN="Nothing to report."
        L_VERIF="TO CHECK"
        ;;
esac

concerns=()

verifier_backend() {
    local nom="$1" disponible="$2"
    local fichier="$heartbeat_dir/$nom.txt"

    if [ "$disponible" = "oui" ]; then
        echo "  $nom : $L_OK"
    else
        echo "  $nom : $L_ABSENT"
    fi

    if [ ! -f "$fichier" ]; then
        if [ "$disponible" = "oui" ]; then
            echo "    -> $L_JAMAIS"
            concerns+=("$nom: $L_JAMAIS")
        fi
        return
    fi

    local derniere
    derniere="$(tail -n 1 "$fichier")"
    local derniere_date="${derniere%% *}"
    local derniere_evenements="${derniere##* }"

    if [ "$derniere_date" = "$YESTERDAY" ]; then
        echo "    -> $L_AJOUR $derniere_evenements $L_EVENEMENTS"
    else
        echo "    -> $L_RETARD $derniere_date ($L_RETARD2)"
        if [ "$disponible" = "oui" ]; then
            concerns+=("$nom: $L_RETARD $derniere_date, $L_RETARD2")
        fi
    fi
}

echo "== $L_DISPO =="
ssh_disponible="non"
if [ -e "$AUTHLOG" ]; then
    ssh_disponible="oui"
elif command -v journalctl >/dev/null 2>&1 \
     && journalctl -u "$UNITE_SSH" -n 1 --no-pager >/dev/null 2>&1; then
    ssh_disponible="oui"
fi
f2b_disponible="non"
command -v fail2ban-client >/dev/null 2>&1 && [ -e "$F2BLOG" ] && f2b_disponible="oui"
crowdsec_disponible="non"
command -v cscli >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && crowdsec_disponible="oui"

echo
echo "== $L_HISTO =="
verifier_backend ssh "$ssh_disponible"
verifier_backend fail2ban "$f2b_disponible"
verifier_backend crowdsec "$crowdsec_disponible"

echo
if [ ${#concerns[@]} -eq 0 ]; then
    echo "$L_RIEN"
    exit 0
else
    echo "$L_VERIF :"
    printf '  - %s\n' "${concerns[@]}" >&2
    exit 1
fi
