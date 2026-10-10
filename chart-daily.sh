#!/bin/bash
# chart-daily.sh — agrège en totaux quotidiens les fichiers par tranche
# horaire produits par les collecteurs, résout une couleur et un libellé
# stables par série, puis appelle chart-daily.gp pour tracer l'historique.
#
# Un futur chart-hourly.sh/.gp réutilisera les mêmes fichiers horaires pour
# une vue par heure du jour : ce script et son .gp s'appellent « daily » et
# non « plot » parce qu'il y aura plus d'une vue.
set -Eeuo pipefail

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
YEAR="${1:-$(date +%Y)}"
IMG_WIDTH="${ARGUS_IMG_WIDTH:-3840}"
IMG_HEIGHT="${ARGUS_IMG_HEIGHT:-2160}"

annee_dir="$DATA_DIR/$YEAR"
daily_dir="$annee_dir/.daily"
images_dir="$annee_dir/images"
mkdir -p "$daily_dir" "$images_dir"
chmod 755 "$annee_dir" "$daily_dir" "$images_dir" 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$DATA_DIR" "$annee_dir" "$daily_dir" "$images_dir" 2>/dev/null || true
fi

shopt -s nullglob
fichiers=("$annee_dir"/*.txt)
shopt -u nullglob

if [ ${#fichiers[@]} -eq 0 ]; then
    echo "chart-daily.sh: no data file for $YEAR in $annee_dir — nothing to plot." >&2
    exit 0
fi

# ── Agrégation horaire -> quotidien, un fichier par série ──────────────────
for f in "${fichiers[@]}"; do
    base="$(basename "$f")"
    gawk '{split($2, a, "T"); c[a[1]] += $1} END {for (d in c) print c[d], d}' "$f" \
        | sort -k2,2 > "$daily_dir/$base"
done

# ── Palette de repli (14 couleurs gnuplot nommées) — utilisée seulement si
#    ARGUS_COULEUR_<nom_assaini> n'est pas définie pour une série. Le choix
#    est un hash stable du nom : même nom -> même couleur, toujours, sans
#    configuration, contrairement à l'attribution par position d'avant.
PALETTE=(white purple green red orange gold blue violet brown magenta yellow pink cyan turquoise)

# ── i18n : titre/axes résolus depuis ARGUS_LANG, pas seulement pour un futur
#    rapport séparé — le graphique quotidien lui-même est concerné.
case "${ARGUS_LANG:-en}" in
    fr) TITRE="Nombre d'attaques par jour" ; XLABEL="Date" ; YLABEL="Nombre d'attaques" ;;
    *)  TITRE="Attacks per day" ; XLABEL="Date" ; YLABEL="Attack count" ;;
esac

# ── Génère le fragment gnuplot (styles + plot) à partir des fichiers réels
#    trouvés cette année — plus de découverte dynamique en `system()` côté
#    .gp, la liste est déjà connue ici, donc les couleurs peuvent être
#    résolues par nom au lieu d'une position qui varie d'une année à l'autre.
fragment="$(mktemp)"
trap 'rm -f "$fragment"' EXIT

{
    idx=0
    plot_parts=()
    label_parts=()
    couleurs_prises=()
    json_series_parts=()
    for f in "$daily_dir"/*.txt; do
        [ -s "$f" ] || continue
        idx=$((idx + 1))
        nom_serie="$(basename "$f" .txt)"
        # Clé de couleur sans le suffixe d'année (ex. "ssh_direct", pas
        # "ssh_direct_2026") — sinon la stabilité d'une année sur l'autre,
        # objectif même de ce mapping, serait cassée par construction.
        nom_sans_annee="${nom_serie%_*}"
        nom_assaini="$(echo "$nom_sans_annee" | tr '-' '_')"
        var_couleur="ARGUS_COULEUR_${nom_assaini}"
        couleur="${!var_couleur:-}"
        if [ -z "$couleur" ]; then
            hash="$(echo -n "$nom_sans_annee" | cksum | cut -d' ' -f1)"
            base=$((hash % ${#PALETTE[@]}))
            couleur="${PALETTE[$base]}"
            # Collision confirmée sur données réelles (vingt jails Plesk
            # réels, deux groupes de quatre séries sur la même couleur au
            # hash brut) — décalage déterministe par ordre alphabétique
            # (ordre de ce parcours, fixé par le glob *.txt) : la première
            # série sur une couleur la garde, la suivante prend la première
            # couleur encore libre de la palette. Sonde circulaire ;
            # au-delà de 14 séries effectivement co-présentes dans un même
            # rendu, la répétition redevient inévitable — limite
            # intrinsèque de la taille de la palette, pas un bug.
            pas=0
            while [ "$pas" -lt "${#PALETTE[@]}" ] \
                  && printf '%s\n' "${couleurs_prises[@]-}" | grep -qx "$couleur"; do
                pas=$((pas + 1))
                couleur="${PALETTE[$(((base + pas) % ${#PALETTE[@]}))]}"
            done
        fi
        couleurs_prises+=("$couleur")
        titre_serie="$(echo "$nom_serie" | tr '_' ' ')"
        echo "set style line $idx lc rgb \"$couleur\" lw 2"
        plot_parts+=("'$f' using 2:1 with linespoints ls $idx title '$titre_serie'")
        label_parts+=("'$f' using 2:1:1 with labels left offset char 0,1 textcolor rgb \"white\" font \",14\" notitle")
        # Objet JSON de la série (contrat d'export, indépendant du PNG) —
        # même nom_sans_annee et même couleur que le rendu gnuplot, une
        # seule résolution de couleur pour les deux consommateurs.
        json_quotidien="$(awk '{printf "%s\"%s\":%s", (NR>1?",":""), $2, $1}' "$f")"
        json_series_parts+=("\"$nom_sans_annee\":{\"couleur\":\"$couleur\",\"quotidien\":{$json_quotidien}}")
    done
    if [ "$idx" -eq 0 ]; then
        echo "set label \"No data\" at graph 0.5,0.5 center textcolor rgb \"white\" font \",20\""
        echo "plot NaN notitle"
    else
        toutes_parts=("${plot_parts[@]}" "${label_parts[@]}")
        ligne="plot $(printf '%s,' "${toutes_parts[@]}")"
        echo "${ligne%,}"
    fi
} > "$fragment"

# ── Contrat d'export JSON — régénéré intégralement à chaque rotation,
#    jamais modifié en place. Les fichiers plats de $daily_dir restent la
#    source de vérité interne ; ce JSON est un artefact jetable et
#    reconstructible depuis eux, au même titre que le PNG. Un futur
#    consommateur (visualiseur, Sillage) lit ce fichier, jamais le format
#    interne shell/gawk des fichiers plats.
json_file="$images_dir/${YEAR}_argus.json"
{
    printf '{"version":1,"annee":%s,"genere_le":"%s","series":{' \
        "$YEAR" "$(date --iso-8601=seconds)"
    IFS=,
    printf '%s' "${json_series_parts[*]-}"
    unset IFS
    printf '}}\n'
} > "$json_file"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARGUS_IMAGES_DIR="$images_dir" \
ARGUS_IMG_WIDTH="$IMG_WIDTH" ARGUS_IMG_HEIGHT="$IMG_HEIGHT" \
ARGUS_TITRE="$TITRE" ARGUS_XLABEL="$XLABEL" ARGUS_YLABEL="$YLABEL" \
ARGUS_FRAGMENT="$fragment" \
    gnuplot "$SCRIPT_DIR/chart-daily.gp"

chmod 644 "$images_dir"/*.png "$json_file" 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$images_dir"/*.png "$json_file" 2>/dev/null || true
fi
