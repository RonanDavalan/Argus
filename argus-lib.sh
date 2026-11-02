#!/bin/bash
# argus-lib.sh — fonctions communes des vues par période : configuration,
# libellés, couleurs stables par série, calcul de fenêtre, liste des séries et
# agrégation des fichiers plats. Se source (. argus-lib.sh), ne s'exécute pas.

# Les variables ARGUS_* déjà présentes dans l'environnement priment sur le
# fichier de configuration, pour pointer une aire d'essai sans le modifier.
argus_charger_config() {
    local conf="${ARGUS_CONF:-/etc/argus/argus.conf}" nom
    local -A env_sauve=()
    while IFS= read -r nom; do
        env_sauve[$nom]="${!nom}"
    done < <(compgen -e | grep '^ARGUS_' || true)
    # shellcheck disable=SC1090
    [ -f "$conf" ] && . "$conf"
    for nom in "${!env_sauve[@]}"; do
        export "$nom=${env_sauve[$nom]}"
    done
    DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
    IMG_WIDTH="${ARGUS_IMG_WIDTH:-3840}"
    IMG_HEIGHT="${ARGUS_IMG_HEIGHT:-2160}"
    LANGUE="${ARGUS_LANG:-en}"
}

# Libellé d'une clé dans la langue ARGUS_LANG (en, fr, de, es) ; en par défaut.
argus_libelle() {
    case "$LANGUE:$1" in
        fr:jour)   echo "Nombre d'attaques par jour" ;;
        de:jour)   echo "Angriffe pro Tag" ;;
        es:jour)   echo "Ataques por día" ;;
        *:jour)    echo "Attacks per day" ;;
        fr:heure)  echo "Nombre d'attaques par heure" ;;
        de:heure)  echo "Angriffe pro Stunde" ;;
        es:heure)  echo "Ataques por hora" ;;
        *:heure)   echo "Attacks per hour" ;;
        fr:x_date) echo "Date" ;;
        de:x_date) echo "Datum" ;;
        es:x_date) echo "Fecha" ;;
        *:x_date)  echo "Date" ;;
        fr:x_heure) echo "Heure" ;;
        de:x_heure) echo "Stunde" ;;
        es:x_heure) echo "Hora" ;;
        *:x_heure)  echo "Hour" ;;
        fr:y)      echo "Nombre d'attaques" ;;
        de:y)      echo "Anzahl der Angriffe" ;;
        es:y)      echo "Número de ataques" ;;
        *:y)       echo "Attack count" ;;
        fr:aucune) echo "Aucune donnée" ;;
        de:aucune) echo "Keine Daten" ;;
        es:aucune) echo "Sin datos" ;;
        *:aucune)  echo "No data" ;;
    esac
}

PALETTE=(white purple green red orange gold blue violet brown magenta yellow pink cyan turquoise)
declare -A COULEUR_DE=()

# Résout la couleur de chaque série de SERIES_TOUTES (ARGUS_COULEUR_<nom> sinon
# hash stable du nom, décalé en cas de collision) : même logique que chart-daily.sh.
# La liste complète sert de base pour qu'un filtre --series ne change aucune couleur.
argus_resoudre_couleurs() {
    local nom nom_assaini var_couleur couleur hash base pas
    local -a prises=()
    COULEUR_DE=()
    for nom in "${SERIES_TOUTES[@]}"; do
        nom_assaini="$(echo "$nom" | tr '-' '_')"
        var_couleur="ARGUS_COULEUR_${nom_assaini}"
        couleur="${!var_couleur:-}"
        if [ -z "$couleur" ]; then
            hash="$(echo -n "$nom" | cksum | cut -d' ' -f1)"
            base=$((hash % ${#PALETTE[@]}))
            couleur="${PALETTE[$base]}"
            pas=0
            while [ "$pas" -lt "${#PALETTE[@]}" ] \
                  && printf '%s\n' "${prises[@]-}" | grep -qx "$couleur"; do
                pas=$((pas + 1))
                couleur="${PALETTE[$(((base + pas) % ${#PALETTE[@]}))]}"
            done
        fi
        prises+=("$couleur")
        COULEUR_DE[$nom]="$couleur"
    done
}

# Date AAAA-MM-JJ valide au calendrier, sinon message et code 1.
argus_date_valide() {
    [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [ "$(date -d "$1" +%F 2>/dev/null)" = "$1" ] && return 0
    echo "argus: invalid date '$1' (expected YYYY-MM-DD)" >&2
    return 1
}

# Calcule la fenêtre : FEN_DEBUT et FEN_FIN (inclus), FEN_TYPE, FEN_ID.
# Usage : argus_calculer_fenetre day|week|month|quarter|year|range <valeur> [<fin>]
argus_calculer_fenetre() {
    local type="$1" v="$2" fin="${3:-}" an sem mois n dow lundi
    FEN_TYPE="$type"
    case "$type" in
        day)
            argus_date_valide "$v" || return 1
            FEN_DEBUT="$v"; FEN_FIN="$v"; FEN_ID="$v" ;;
        week)
            if ! [[ "$v" =~ ^[0-9]{4}-W[0-9]{2}$ ]]; then
                echo "argus: invalid week '$v' (expected YYYY-Www)" >&2; return 1
            fi
            an="${v%-W*}"; sem=$((10#${v#*-W}))
            dow="$(date -d "$an-01-04" +%u)"
            lundi="$(date -d "$an-01-04 -$((dow - 1)) days +$(((sem - 1) * 7)) days" +%F)"
            if [ "$sem" -lt 1 ] || [ "$(date -d "$lundi" +%G-W%V)" != "$v" ]; then
                echo "argus: week '$v' does not exist" >&2; return 1
            fi
            FEN_DEBUT="$lundi"; FEN_FIN="$(date -d "$lundi +6 days" +%F)"; FEN_ID="$v" ;;
        month)
            if ! [[ "$v" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]; then
                echo "argus: invalid month '$v' (expected YYYY-MM)" >&2; return 1
            fi
            FEN_DEBUT="$v-01"; FEN_FIN="$(date -d "$v-01 +1 month -1 day" +%F)"; FEN_ID="$v" ;;
        quarter)
            if ! [[ "$v" =~ ^[0-9]{4}-Q[1-4]$ ]]; then
                echo "argus: invalid quarter '$v' (expected YYYY-Qn, n from 1 to 4)" >&2; return 1
            fi
            an="${v%-Q*}"; n="${v#*-Q}"; mois="$(printf '%02d' $(((n - 1) * 3 + 1)))"
            FEN_DEBUT="$an-$mois-01"; FEN_FIN="$(date -d "$FEN_DEBUT +3 months -1 day" +%F)"; FEN_ID="$v" ;;
        year)
            if ! [[ "$v" =~ ^[0-9]{4}$ ]]; then
                echo "argus: invalid year '$v' (expected YYYY)" >&2; return 1
            fi
            FEN_DEBUT="$v-01-01"; FEN_FIN="$v-12-31"; FEN_ID="$v" ;;
        range)
            argus_date_valide "$v" || return 1
            argus_date_valide "$fin" || return 1
            if [[ "$v" > "$fin" ]]; then
                echo "argus: --from ($v) is after --to ($fin)" >&2; return 1
            fi
            FEN_DEBUT="$v"; FEN_FIN="$fin"; FEN_ID="${v}_${fin}" ;;
        *) echo "argus: unknown window type '$type'" >&2; return 1 ;;
    esac
}

# Années couvertes par la fenêtre : une fenêtre à cheval sur deux années lit
# les deux dossiers.
argus_annees_fenetre() {
    local a
    for ((a = ${FEN_DEBUT:0:4}; a <= ${FEN_FIN:0:4}; a++)); do echo "$a"; done
}

# Remplit SERIES_TOUTES (séries ayant un fichier dans les années de la fenêtre,
# nom sans suffixe d'année, ordre alphabétique) puis SERIES (après le filtre
# SERIES_FILTRE, liste séparée par des virgules). Code 1 si un nom est inconnu.
argus_lister_series() {
    local an f nom voulue trouvee
    SERIES_TOUTES=()
    SERIES=()
    while IFS= read -r nom; do
        [ -n "$nom" ] && SERIES_TOUTES+=("$nom")
    done < <(
        for an in $(argus_annees_fenetre); do
            for f in "$DATA_DIR/$an"/*_"$an".txt; do
                [ -f "$f" ] || continue
                nom="$(basename "$f" .txt)"
                echo "${nom%_*}"
            done
        done | LC_ALL=C sort -u
    )
    if [ -z "${SERIES_FILTRE:-}" ]; then
        SERIES=("${SERIES_TOUTES[@]}")
        return 0
    fi
    local IFS=,
    for voulue in $SERIES_FILTRE; do
        trouvee=0
        for nom in "${SERIES_TOUTES[@]}"; do
            [ "$nom" = "$voulue" ] && trouvee=1
        done
        if [ "$trouvee" -eq 0 ]; then
            echo "argus: unknown series '$voulue' (available: ${SERIES_TOUTES[*]-none})" >&2
            return 1
        fi
        SERIES+=("$voulue")
    done
}

# Tableau agrégé d'une sous-fenêtre sur la sortie standard : une ligne
# d'en-tête « #date<TAB>série… », puis une ligne par jour (granularité « day »)
# ou par heure d'un jour unique (« hour »), les périodes sans donnée à 0.
# Usage : argus_tableau <début> <fin> day|hour   (utilise SERIES)
argus_tableau() {
    local debut="$1" fin="$2" gran="$3" an nom
    local -a fichiers=(/dev/null)
    for an in $(argus_annees_fenetre); do
        for nom in "${SERIES[@]}"; do
            [ -f "$DATA_DIR/$an/${nom}_${an}.txt" ] && fichiers+=("$DATA_DIR/$an/${nom}_${an}.txt")
        done
    done
    local liste
    liste="$(IFS=,; echo "${SERIES[*]}")"
    TZ=UTC gawk -v debut="$debut" -v fin="$fin" -v gran="$gran" -v series="$liste" '
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
            cle = (gran == "hour") ? $2 : jour
            c[nom, cle] += $1
        }
        END {
            printf "#date"
            for (i = 1; i <= n; i++) printf "\t%s", S[i]
            printf "\n"
            split(debut, p, "-")
            t = mktime(p[1] " " p[2] " " p[3] " 12 00 00")
            for (;; t += 86400) {
                jour = strftime("%Y-%m-%d", t)
                if (jour > fin) break
                if (gran == "hour") {
                    for (h = 0; h < 24; h++) ligne(sprintf("%sT%02d", jour, h))
                } else ligne(jour)
            }
        }
        function ligne(cle,   i) {
            printf "%s", cle
            for (i = 1; i <= n; i++) printf "\t%d", c[S[i], cle]
            printf "\n"
        }
    ' "${fichiers[@]}"
}
