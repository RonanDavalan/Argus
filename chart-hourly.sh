#!/bin/bash
# chart-hourly.sh — trace, pour chaque série, le nombre d'attaques par heure du
# jour (0 à 23) cumulé sur une fenêtre au choix, une ligne par série,
# superposées et jamais additionnées. Lit les fichiers plats des collecteurs ;
# ne modifie rien d'autre que les PNG qu'il écrit.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/argus-lib.sh"

usage() {
    cat <<'HELP'
Usage: chart-hourly.sh [options]

Plots, for each series, the attack count per hour of the day (24 positions,
00 to 23) summed over a time window, as a PNG. Series are overlaid, never
summed. The hour is the one written by the collectors, i.e. the local server
time at which the attack was observed in the logs. Reads the flat files
$ARGUS_DATA_DIR/<year>/<series>_<year>.txt.

A series whose slices are all at hour 00 (a daily leftover from the migration
to hourly data) is excluded: a message goes to standard error and the title
of the chart says so.

Window (one of; default: the current year):
  --day YYYY-MM-DD        one day
  --week YYYY-Www         ISO 8601 week (Monday to Sunday), e.g. 2026-W44
  --month YYYY-MM         one calendar month
  --quarter YYYY-Qn       one quarter, n from 1 to 4
  --year YYYY             one calendar year
  --from YYYY-MM-DD --to YYYY-MM-DD
                          explicit range, both days included
  A window spanning two years reads the data directories of both.

Options:
  --series a,b            only these series (names without the year suffix)
  --list-series           print the plotted series of the window and exit
  --out DIR               output directory (default: <data dir>/<year>/images)
  --print-data            print the aggregated table on standard output
                          (tab-separated, header line starts with #, 24 lines)
                          and exit
  -h, --help              show this help

Output: <out>/<YYYY-MM-DD>_argus_hourly_<window>.png, where the date is today
and <window> is e.g. week-2026-W44 or month-2026-10.

Configuration: /etc/argus/argus.conf (ARGUS_DATA_DIR, ARGUS_LANG, ARGUS_IMG_WIDTH,
ARGUS_IMG_HEIGHT, ARGUS_COULEUR_<series>); variables already set in the
environment take precedence over the file.

Exit codes: 0 success, 2 invalid usage or unknown series.
HELP
}

erreur_usage() { echo "chart-hourly.sh: $1 (see --help)" >&2; exit 2; }

TYPE=""; VALEUR=""; DU=""; AU=""
SERIES_FILTRE=""; OUT=""; LISTER=0; IMPRIMER=0

choisir_fenetre() {
    [ -z "$TYPE" ] || erreur_usage "only one of --day, --week, --month, --quarter, --year, --from/--to may be given"
    TYPE="$1"; VALEUR="${2:?}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --day|--week|--month|--quarter|--year)
            [ $# -ge 2 ] || erreur_usage "$1 needs a value"
            choisir_fenetre "${1#--}" "$2"; shift 2 ;;
        --from) [ $# -ge 2 ] || erreur_usage "--from needs a value"; DU="$2"; shift 2 ;;
        --to)   [ $# -ge 2 ] || erreur_usage "--to needs a value"; AU="$2"; shift 2 ;;
        --series) [ $# -ge 2 ] || erreur_usage "--series needs a value"; SERIES_FILTRE="$2"; shift 2 ;;
        --out) [ $# -ge 2 ] || erreur_usage "--out needs a directory"; OUT="$2"; shift 2 ;;
        --list-series) LISTER=1; shift ;;
        --print-data) IMPRIMER=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) erreur_usage "unknown option '$1'" ;;
    esac
done

if [ -n "$DU$AU" ]; then
    [ -n "$DU" ] && [ -n "$AU" ] || erreur_usage "--from and --to go together"
    choisir_fenetre range "$DU"
fi
[ -n "$TYPE" ] || { TYPE=year; VALEUR="$(date +%Y)"; }

for outil in gawk gnuplot date; do
    command -v "$outil" >/dev/null 2>&1 || { echo "chart-hourly.sh: $outil is required" >&2; exit 2; }
done

argus_charger_config
argus_calculer_fenetre "$TYPE" "$VALEUR" "$AU" || exit 2
argus_lister_series || exit 2

# Une série dont toutes les tranches de tous ses fichiers valent T00 est un
# reliquat journalier : la répartir par heure n'aurait aucun sens.
EXCLUES=()
retenues=()
for nom in "${SERIES[@]}"; do
    reliquat=1
    for an in $(argus_annees_fenetre); do
        f="$DATA_DIR/$an/${nom}_${an}.txt"
        [ -f "$f" ] || continue
        if gawk '$2 !~ /T00$/ { exit 1 }' "$f"; then :; else reliquat=0; fi
    done
    if [ "$reliquat" -eq 1 ]; then
        EXCLUES+=("$nom")
        echo "chart-hourly.sh: series '$nom' excluded: all its slices are at hour 00 (daily data, no hourly depth)" >&2
    else
        retenues+=("$nom")
    fi
done
SERIES=("${retenues[@]}")

if [ "$LISTER" -eq 1 ]; then
    [ ${#SERIES[@]} -gt 0 ] && printf '%s\n' "${SERIES[@]}"
    exit 0
fi

# Tableau de la fenêtre : « #hour<TAB>série… », une ligne par heure de 0 à 23.
tableau_horaire() {
    local an nom liste
    local -a fichiers=(/dev/null)
    for an in $(argus_annees_fenetre); do
        for nom in "${SERIES[@]}"; do
            [ -f "$DATA_DIR/$an/${nom}_${an}.txt" ] && fichiers+=("$DATA_DIR/$an/${nom}_${an}.txt")
        done
    done
    liste="$(IFS=,; echo "${SERIES[*]}")"
    gawk -v debut="$FEN_DEBUT" -v fin="$FEN_FIN" -v series="$liste" '
        BEGIN {
            n = split(series, S, ",")
            if (series == "") n = 0
        }
        FNR == 1 {
            nom = FILENAME; sub(/.*\//, "", nom); sub(/\.txt$/, "", nom); sub(/_[0-9]+$/, "", nom)
        }
        $2 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]$/ {
            jour = substr($2, 1, 10)
            if (jour < debut || jour > fin) next
            c[nom, substr($2, 12, 2) + 0] += $1
        }
        END {
            printf "#hour"
            for (i = 1; i <= n; i++) printf "\t%s", S[i]
            printf "\n"
            for (h = 0; h < 24; h++) {
                printf "%d", h
                for (i = 1; i <= n; i++) printf "\t%d", c[S[i], h]
                printf "\n"
            }
        }
    ' "${fichiers[@]}"
}

if [ "$IMPRIMER" -eq 1 ]; then
    tableau_horaire
    exit 0
fi

argus_resoudre_couleurs

images_dir="${OUT:-$DATA_DIR/${FEN_DEBUT:0:4}/images}"
mkdir -p "$images_dir"
if [ -z "$OUT" ]; then
    chmod 755 "$images_dir" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$images_dir" 2>/dev/null || true
    fi
fi

fichier="$images_dir/$(date +%F)_argus_hourly_${FEN_TYPE}-${FEN_ID}.png"
tableau="$(tableau_horaire)"

titre="$(argus_libelle titre_horaire) — $FEN_DEBUT → $FEN_FIN"
[ "$FEN_DEBUT" = "$FEN_FIN" ] && titre="$(argus_libelle titre_horaire) — $FEN_DEBUT"
if [ ${#EXCLUES[@]} -gt 0 ]; then
    titre="$titre — $(argus_libelle exclue): $(IFS=,; echo "${EXCLUES[*]}")"
fi

{
    cat "$SCRIPT_DIR/chart-hourly.gp"
    printf '$DONNEES << EOD\n%s\nEOD\n' "$tableau"
    if [ ${#SERIES[@]} -eq 0 ]; then
        echo "set label \"$(argus_libelle aucune)\" at graph 0.5,0.5 center textcolor rgb \"white\" font \",20\""
        echo "plot NaN notitle"
    else
        parts=(); i=0
        for nom in "${SERIES[@]}"; do
            i=$((i + 1)); col=$((i + 1))
            echo "set style line $i lc rgb \"${COULEUR_DE[$nom]}\" lw 2"
            parts+=("\$DONNEES using 1:$col with linespoints ls $i title '$(echo "$nom" | tr '_' ' ')'")
        done
        ligne="plot $(printf '%s, ' "${parts[@]}")"
        echo "${ligne%, }"
    fi
    echo "unset output"
} | ARGUS_OUT_FILE="$fichier" ARGUS_IMG_WIDTH="$IMG_WIDTH" ARGUS_IMG_HEIGHT="$IMG_HEIGHT" \
    ARGUS_TITRE="$titre" ARGUS_XLABEL="$(argus_libelle x_heure)" ARGUS_YLABEL="$(argus_libelle y)" gnuplot

chmod 644 "$fichier" 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$fichier" 2>/dev/null || true
fi
echo "$fichier"
