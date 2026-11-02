#!/bin/bash
# chart-period.sh — trace le nombre d'attaques de chaque série sur une fenêtre
# au choix (jour, semaine ISO, mois, trimestre, année, plage), une ligne par
# série, superposées et jamais additionnées. Lit les fichiers plats des
# collecteurs ; ne modifie rien d'autre que les PNG qu'il écrit.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/argus-lib.sh"

usage() {
    cat <<'HELP'
Usage: chart-period.sh [options]

Plots the attack count of each series over a time window as a PNG, one line
per series (series are overlaid, never summed). Reads the flat files
$ARGUS_DATA_DIR/<year>/<series>_<year>.txt written by the collectors.

Window (one of; default: the current year):
  --day YYYY-MM-DD        one day, one point per hour
  --week YYYY-Www         ISO 8601 week (Monday to Sunday), e.g. 2026-W44
  --month YYYY-MM         one calendar month
  --quarter YYYY-Qn       one quarter, n from 1 to 4
  --year YYYY             one calendar year
  --from YYYY-MM-DD --to YYYY-MM-DD
                          explicit range, both days included
  A window spanning two years reads the data directories of both.

Options:
  --series a,b            only these series (names without the year suffix)
  --list-series           print the series available in the window and exit
  --split week|month      one PNG per ISO week or calendar month of the window
                          (week: windows longer than one week; month: windows
                          spanning more than one month); sub-periods are
                          clipped to the window
  --out DIR               output directory (default: <data dir>/<year>/images)
  --print-data            print the aggregated table on standard output
                          (tab-separated, header line starts with #) and exit
  -h, --help              show this help

Output: <out>/<YYYY-MM-DD>_argus_period_<window>.png, where the date is today
and <window> is e.g. week-2026-W44, month-2026-10 or
range-2025-12-01_2026-01-31. With --split, <window> is
<parent>_<sub-period>, e.g. month-2026-10_week-2026-W41.

Configuration: /etc/argus/argus.conf (ARGUS_DATA_DIR, ARGUS_LANG, ARGUS_IMG_WIDTH,
ARGUS_IMG_HEIGHT, ARGUS_COULEUR_<series>); variables already set in the
environment take precedence over the file.

Exit codes: 0 success, 2 invalid usage or unknown series.
HELP
}

erreur_usage() { echo "chart-period.sh: $1 (see --help)" >&2; exit 2; }

TYPE=""; VALEUR=""; DU=""; AU=""
SERIES_FILTRE=""; SPLIT=""; OUT=""; LISTER=0; IMPRIMER=0

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
        --split)
            [ $# -ge 2 ] || erreur_usage "--split needs week or month"
            case "$2" in week|month) SPLIT="$2" ;; *) erreur_usage "--split takes week or month" ;; esac
            shift 2 ;;
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
    command -v "$outil" >/dev/null 2>&1 || { echo "chart-period.sh: $outil is required" >&2; exit 2; }
done

argus_charger_config
argus_calculer_fenetre "$TYPE" "$VALEUR" "$AU" || exit 2
argus_lister_series || exit 2

if [ "$LISTER" -eq 1 ]; then
    [ ${#SERIES[@]} -gt 0 ] && printf '%s\n' "${SERIES[@]}"
    exit 0
fi

# Un jour unique se trace à l'heure ; toute autre fenêtre se trace au jour.
GRAN=day
[ "$FEN_DEBUT" = "$FEN_FIN" ] && GRAN=hour

if [ "$IMPRIMER" -eq 1 ]; then
    argus_tableau "$FEN_DEBUT" "$FEN_FIN" "$GRAN"
    exit 0
fi

# Découpage en sous-fenêtres « début fin type id », bornées à la fenêtre.
SOUS=()
if [ -n "$SPLIT" ]; then
    case "$SPLIT:$FEN_TYPE" in
        week:day|week:week) erreur_usage "--split week needs a window longer than one week" ;;
        month:day|month:week|month:month) erreur_usage "--split month needs a window spanning several months" ;;
    esac
    curseur="$FEN_DEBUT"
    while [[ ! "$curseur" > "$FEN_FIN" ]]; do
        if [ "$SPLIT" = week ]; then
            jsem="$(date -d "$curseur" +%u)"
            fin_sous="$(date -d "$curseur +$((7 - jsem)) days" +%F)"
            id_sous="$(date -d "$curseur" +%G-W%V)"
        else
            fin_sous="$(date -d "${curseur:0:7}-01 +1 month -1 day" +%F)"
            id_sous="${curseur:0:7}"
        fi
        [[ "$fin_sous" > "$FEN_FIN" ]] && fin_sous="$FEN_FIN"
        SOUS+=("$curseur $fin_sous $SPLIT $id_sous")
        curseur="$(date -d "$fin_sous +1 day" +%F)"
    done
else
    SOUS+=("$FEN_DEBUT $FEN_FIN $FEN_TYPE $FEN_ID")
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

# Trace une sous-fenêtre : <début> <fin> <type> <id>.
tracer() {
    local debut="$1" fin="$2" type="$3" id="$4" tableau lignes i col nom titre_serie
    local nom_fenetre="$FEN_TYPE-$FEN_ID" gran="$GRAN" fichier titre fmt_tps fmt_axe xlabel
    [ -n "$SPLIT" ] && nom_fenetre="$FEN_TYPE-$FEN_ID""_$type-$id"
    [ "$debut" = "$fin" ] && gran=hour || gran=day
    fichier="$images_dir/$(date +%F)_argus_period_${nom_fenetre}.png"

    tableau="$(argus_tableau "$debut" "$fin" "$gran")"
    lignes=$(($(printf '%s\n' "$tableau" | wc -l) - 1))

    if [ "$gran" = hour ]; then
        titre="$(argus_libelle heure) — $debut"
        fmt_tps="%Y-%m-%dT%H"; fmt_axe="%H:00"; xlabel="$(argus_libelle x_heure)"
        xrange="[\"${debut}T00\":\"${debut}T23\"]"
    else
        titre="$(argus_libelle jour) — $debut → $fin"
        fmt_tps="%Y-%m-%d"; fmt_axe="%m-%d"; xlabel="$(argus_libelle x_date)"
        xrange="[\"$debut\":\"$fin\"]"
    fi
    [ "$FEN_TYPE" != range ] && [ -z "$SPLIT" ] && titre="$titre ($FEN_ID)"

    {
        cat "$SCRIPT_DIR/chart-period.gp"
        printf '$DONNEES << EOD\n%s\nEOD\n' "$tableau"
        echo "set xrange $xrange"
        if [ ${#SERIES[@]} -eq 0 ]; then
            echo "set label \"$(argus_libelle aucune)\" at graph 0.5,0.5 center textcolor rgb \"white\" font \",20\""
            echo "plot NaN notitle"
        else
            local parts=() style="lines"
            [ "$lignes" -le 60 ] && style="linespoints"
            i=0
            for nom in "${SERIES[@]}"; do
                i=$((i + 1)); col=$((i + 1))
                titre_serie="$(echo "$nom" | tr '_' ' ')"
                echo "set style line $i lc rgb \"${COULEUR_DE[$nom]}\" lw 2"
                parts+=("\$DONNEES using 1:$col with $style ls $i title '$titre_serie'")
                [ "$lignes" -le 31 ] && parts+=("\$DONNEES using 1:$col:(\$$col > 0 ? sprintf('%d', \$$col) : '') with labels left offset char 0,1 textcolor rgb \"white\" font \",14\" notitle")
            done
            local ligne
            ligne="plot $(printf '%s, ' "${parts[@]}")"
            echo "${ligne%, }"
        fi
        echo "unset output"
    } | ARGUS_OUT_FILE="$fichier" ARGUS_IMG_WIDTH="$IMG_WIDTH" ARGUS_IMG_HEIGHT="$IMG_HEIGHT" \
        ARGUS_TITRE="$titre" ARGUS_XLABEL="$xlabel" ARGUS_YLABEL="$(argus_libelle y)" \
        ARGUS_TIMEFMT="$fmt_tps" ARGUS_XFORMAT="$fmt_axe" gnuplot

    chmod 644 "$fichier" 2>/dev/null || true
    if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
        chown "$ARGUS_DATA_OWNER" "$fichier" 2>/dev/null || true
    fi
    echo "$fichier"
}

for sous in "${SOUS[@]}"; do
    # shellcheck disable=SC2086
    tracer $sous
done
