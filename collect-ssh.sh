#!/bin/bash
# collect-ssh.sh — compte les attaques SSH directement depuis les journaux
# système, sans dépendre de fail2ban, de CrowdSec ni d'aucun autre outil de
# prévention d'intrusion. Deux sources, essayées dans l'ordre : auth.log
# (systèmes avec rsyslog), puis journald (systèmes sans rsyslog, de plus en
# plus fréquents sur Debian). Celle qui existe est utilisée sans configuration.
#
# Une « attaque » est une IP source qui atteint ARGUS_SSH_THRESHOLD
# tentatives d'authentification échouées dans une même journée : un seul mot
# de passe mal saisi par un utilisateur légitime n'est pas compté. C'est ce
# que déciderait une jail d'un IPS, sans en exiger un.
#
# Lancé une fois par jour (cron), traite la veille entière. Sortie : un
# fichier texte plat par année, une ligne par tranche (date, heure) qui a vu
# au moins une attaque qualifiante : « <compte> <AAAA-MM-JJTHH> ». Idempotent :
# deux lancements le même jour ne dupliquent pas l'entrée.
set -Eeuo pipefail

# auth.log utilise les abréviations de mois anglaises quelle que soit la
# locale du système (format syslog traditionnel) — forcer LC_TIME=C est
# impératif : sans ça, `date` produit "juil." sur un système en locale
# française, qui ne correspondra jamais à "Jul" dans le journal réel.
export LC_TIME=C

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
THRESHOLD="${ARGUS_SSH_THRESHOLD:-5}"
AUTHLOG="${ARGUS_AUTHLOG:-/var/log/auth.log}"
UNITE_SSH="${ARGUS_SSHD_UNIT:-ssh}"

YESTERDAY="$(date -d yesterday '+%Y-%m-%d')"
YEAR="$(date -d yesterday '+%Y')"

annee_dir="$DATA_DIR/$YEAR"
sortie="$annee_dir/ssh_direct_$YEAR.txt"

mkdir -p "$annee_dir"
chmod 755 "$annee_dir" 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$DATA_DIR" "$annee_dir" 2>/dev/null || true
fi

# Déjà collecté aujourd'hui pour cette date ? Idempotent.
if [ -f "$sortie" ] && grep -q "^[[:space:]]*[0-9]\+ ${YESTERDAY}T" "$sortie"; then
    exit 0
fi

# ── Deux extracteurs, un format commun en sortie : "<date> <heure> <ip>",
#    une ligne par tentative échouée qualifiante. Le seuillage par IP
#    (seuiller(), plus bas) ne connaît plus le format d'origine.

# auth.log : "Failed password" couvre utilisateur valide et invalide
# ("Invalid user" seul est toujours suivi de "Failed password for invalid
# user ... from IP", événement canonique unique, pas de double-comptage).
# gawk requis (Depends: gawk) : match() à 3 arguments avec capture de groupe
# est une extension gawk, absente de mawk (l'awk par défaut sur Debian).
extraire_authlog() {
    gawk -v annee="$YEAR" -v jour="$YESTERDAY" '
        BEGIN {
            split("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec", mnoms, ",");
            for (i=1; i<=12; i++) moisnum[mnoms[i]] = sprintf("%02d", i);
        }
        {
            if (!match($0, /Failed password for( invalid user)? [^ ]+ from ([0-9a-fA-F:.]+)/, m)) next;
            date = annee"-"moisnum[$1]"-"sprintf("%02d", $2);
            if (date != jour) next;
            print date, substr($3, 1, 2), m[2];
        }
    '
}

# journald (systemd) : utilisé uniquement si auth.log est absent — systèmes
# Debian minimaux sans rsyslog, où les échecs SSH n'existent que là.
# Sortie ISO (`-o short-iso`) : pas de dépendance à la locale, contrairement
# à auth.log — la date/heure se lit directement sur les 13 premiers
# caractères ("2026-07-20T14"), sans mapping de nom de mois.
extraire_journald() {
    gawk -v jour="$YESTERDAY" '
        {
            if (!match($0, /Failed password for( invalid user)? [^ ]+ from ([0-9a-fA-F:.]+)/, m)) next;
            date = substr($1, 1, 10);
            if (date != jour) next;
            print date, substr($1, 12, 2), m[2];
        }
    '
}

# Seuillage : lit "<date> <heure> <ip>" sur stdin, émet "<date>T<heure>" une
# fois par IP qui franchit ARGUS_SSH_THRESHOLD ce jour-là — pas avant (pas
# une attaque), pas après (une IP ne compte qu'une fois/jour).
seuiller() {
    gawk -v seuil="$THRESHOLD" '{ if (++n[$3] == seuil) print $1"T"$2 }'
}

# Localise le(s) fichier(s) auth.log contenant la date de la veille — tourne
# en général une fois par semaine (logrotate), donc presque toujours dans le
# fichier courant ; retombe sur auth.log.1[.gz] si la rotation vient d'avoir
# lieu. %e (GNU date) pad le jour d'un espace, exactement le format syslog
# ("Jul  3" / "Jul 21") — ne pas utiliser %d ici.
PATRON_SYSLOG="$(date -d yesterday '+%b %e')"
sources=()
for f in "$AUTHLOG" "$AUTHLOG.1" "$AUTHLOG.1.gz"; do
    [ -e "$f" ] || continue
    case "$f" in
        *.gz) zgrep -q "^${PATRON_SYSLOG}" "$f" 2>/dev/null && sources+=("$f") ;;
        *)    grep -q "^${PATRON_SYSLOG}" "$f" 2>/dev/null && sources+=("$f") ;;
    esac
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [ ${#sources[@]} -gt 0 ]; then
    for f in "${sources[@]}"; do
        case "$f" in
            *.gz) zcat "$f" ;;
            *)    cat "$f" ;;
        esac
    done | extraire_authlog | seuiller | sort | uniq -c >> "$tmp"
elif command -v journalctl >/dev/null 2>&1; then
    journalctl -u "$UNITE_SSH" --no-pager -o short-iso \
        --since "$YESTERDAY 00:00:00" --until "$YESTERDAY 23:59:59" 2>/dev/null \
        | extraire_journald | seuiller | sort | uniq -c >> "$tmp"
fi

if [ -s "$tmp" ]; then
    cat "$tmp" >> "$sortie"
    chmod 644 "$sortie" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$sortie" 2>/dev/null || true
    fi
fi

# ── Battement de vie — distinct des fichiers de données ci-dessus, qui ne
#    contiennent jamais de ligne pour un jour sans attaque qualifiante. Sans
#    ce fichier séparé, une vraie journée calme et une collecte cassée sont
#    indiscernables l'une de l'autre. Une ligne par jour, y compris à zéro ;
#    idempotence propre à ce fichier (pas celle de $sortie, qui ne voit
#    jamais un jour à zéro).
heartbeat_dir="$annee_dir/.heartbeat"
heartbeat_file="$heartbeat_dir/ssh.txt"
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
