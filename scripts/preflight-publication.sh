#!/usr/bin/env bash
# preflight-publication.sh — checks for real infrastructure tokens in the
# repository before a public push. Scans by content, across every extension
# that can carry a leak (.md/.sh/.gp/debian/*) — never by a single assumed
# file type. A scan restricted to one file type is a known, real way for a
# credential to pass through undetected in files of a different type.
#
# Usage:
#   bash scripts/preflight-publication.sh [--verbose] [--historique]
#
# --historique : also audits the full git history (git log --all -p), not
#   just the working tree — a leak introduced then "fixed" in a later commit
#   stays invisible to a working-tree-only scan forever. Not run automatically
#   by any hook; manual or scheduled CI use only.
#
# Exit 0 — no leak, publication possible.
# Exit 1 — at least one leak found, publication blocked.
set -euo pipefail

VERBOSE=0
HISTORIQUE=0
for arg in "$@"; do
    case "$arg" in
        --verbose)    VERBOSE=1 ;;
        --historique) HISTORIQUE=1 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── Generic patterns (public, no real value) ─────────────────────────────
# Format: "label;;;extended_regex;;;recommendation". ';;;' separator avoids
# collision with regex alternation '|'.
PATTERNS=(
    "LAN IP 192.168.x.x;;;\\b192\\.168\\.[0-9]+\\.[0-9]+\\b;;;replace with __LAN_IP__"
    "LAN IP 10.x.x.x;;;\\b10\\.[0-9]+\\.[0-9]+\\.[0-9]+\\b;;;replace with __LAN_IP__"
    "LAN IP 172.16-31.x.x;;;\\b172\\.(1[6-9]|2[0-9]|3[0-1])\\.[0-9]+\\.[0-9]+\\b;;;replace with __LAN_IP__"
)

# ── Documented exceptions ─────────────────────────────────────────────────
# Format: "filepath;;;pattern_label;;;reason". Empty by default.
EXCEPTIONS=()

# ── Private (instance) patterns ───────────────────────────────────────────
# Never committed to this repository — real hostnames, real IPs, real
# usernames live outside it (method/instance split, see
# SPECIFICATIONS/PROCEDURES_LLM/INDEX.md in the private _CADRE). Absent =
# scan reduced to the generic patterns above + the structural checks below —
# clean degradation, never a loud failure, including for a third party who
# clones this repository without the private _CADRE.
PATTERNS_PRIVES="${ARGUS_PREFLIGHT_PATTERNS:-$HOME/git/Argus/_CADRE/SPECIFICATIONS/PROCEDURES_LLM/instance/preflight_patterns.sh}"
if [[ -f "$PATTERNS_PRIVES" ]]; then
    # shellcheck disable=SC1090
    source "$PATTERNS_PRIVES"
    echo "Private patterns: loaded ($PATTERNS_PRIVES)"
else
    echo "Private patterns: absent — scan reduced to generic patterns"
fi

est_exempte() {
    local fichier="$1" label="$2"
    local exc exc_fichier exc_reste exc_label
    for exc in "${EXCEPTIONS[@]}"; do
        exc_fichier="${exc%%;;;*}"
        exc_reste="${exc#*;;;}"
        exc_label="${exc_reste%%;;;*}"
        if [[ "$fichier" == "$exc_fichier" && "$label" == "$exc_label" ]]; then
            EXEMPTE_RAISON="${exc_reste#*;;;}"
            return 0
        fi
    done
    return 1
}

# ── Scope discovery ────────────────────────────────────────────────────────
mapfile -d '' FICHIERS < <(find . -type f \( \
    -name '*.md' -o -name '*.sh' -o -name '*.gp' -o -path './debian/*' \
    \) \
    -not -path './.git/*' \
    -not -path './debian/.debhelper/*' \
    -not -path './debian/argus/*' \
    -not -path './debian/debhelper-build-stamp' \
    -not -path './debian/argus.substvars' \
    -not -path './debian/files' \
    -not -path './debian/*.log' \
    -print0)

NB_FICHIERS=${#FICHIERS[@]}

echo "=== Argus preflight publication ==="
echo "Repo    : $REPO_ROOT"
echo "Scope   : $NB_FICHIERS file(s) — .md/.sh/.gp + debian/* (excl. .git/, build artefacts)"
echo "Patterns: ${#PATTERNS[@]} forbidden"
echo

if [[ $VERBOSE -eq 1 && $NB_FICHIERS -gt 0 ]]; then
    echo "--- Placeholders already in place (positive audit) ---"
    grep -hoE '__[A-Z][A-Z_]+__' "${FICHIERS[@]}" 2>/dev/null \
        | sort | uniq -c | sort -rn \
        | awk '{printf "  %-30s %s occurrences\n", $2, $1}' || true
    echo
fi

NB_FUITES=0
declare -A FUITES_PAR_PATTERN

if [[ $NB_FICHIERS -gt 0 ]]; then
    for entree in "${PATTERNS[@]}"; do
        label="${entree%%;;;*}"
        reste="${entree#*;;;}"
        regex="${reste%%;;;*}"
        recommandation="${reste#*;;;}"
        if matches=$(grep -EinH "$regex" "${FICHIERS[@]}" 2>/dev/null); then
            while IFS= read -r ligne; do
                [[ -z "$ligne" ]] && continue
                fichier_match="${ligne%%:*}"
                if est_exempte "$fichier_match" "$label"; then
                    [[ $VERBOSE -eq 1 ]] && echo "SKIP  [$label] $ligne (exception: $EXEMPTE_RAISON)"
                else
                    NB_FUITES=$((NB_FUITES + 1))
                    FUITES_PAR_PATTERN["$label"]=$(( ${FUITES_PAR_PATTERN["$label"]:-0} + 1 ))
                    echo "LEAK [$label] $ligne"
                    echo "       -> $recommandation"
                fi
            done <<< "$matches"
        fi
    done
fi

# ── Historical audit (--historique) ───────────────────────────────────────
NB_FUITES_HISTORIQUE=0
declare -A FUITES_HISTORIQUE_PAR_PATTERN

if [[ $HISTORIQUE -eq 1 ]]; then
    echo "--- Historical audit (git log --all -p) ---"
    for entree in "${PATTERNS[@]}"; do
        label="${entree%%;;;*}"
        reste="${entree#*;;;}"
        regex="${reste%%;;;*}"
        recommandation="${reste#*;;;}"
        fichier_courant=""
        while IFS= read -r ligne; do
            if [[ "$ligne" == "diff --git a/"* ]]; then
                fichier_courant="./$(echo "$ligne" | sed -E 's#^diff --git a/(.*) b/.*#\1#')"
                continue
            fi
            case "$ligne" in
                +++*|---*) continue ;;
                [+-]*) ;;
                *) continue ;;
            esac
            if echo "$ligne" | grep -Eiq -- "$regex"; then
                if est_exempte "$fichier_courant" "$label"; then
                    [[ $VERBOSE -eq 1 ]] && echo "SKIP HIST [$label] $fichier_courant: ${ligne:0:200} (exception: $EXEMPTE_RAISON)"
                else
                    NB_FUITES_HISTORIQUE=$((NB_FUITES_HISTORIQUE + 1))
                    FUITES_HISTORIQUE_PAR_PATTERN["$label"]=$(( ${FUITES_HISTORIQUE_PAR_PATTERN["$label"]:-0} + 1 ))
                    echo "HISTORICAL LEAK [$label] $fichier_courant: ${ligne:0:200}"
                    echo "       -> $recommandation"
                fi
            fi
        done < <(git log --all -p -E -G"$regex" -- . 2>/dev/null)
    done
    echo
    echo "=== Historical summary ==="
    if [[ $NB_FUITES_HISTORIQUE -eq 0 ]]; then
        echo "OK — no historical leak."
    else
        for label in "${!FUITES_HISTORIQUE_PAR_PATTERN[@]}"; do
            printf "  %-30s %s occurrences\n" "$label" "${FUITES_HISTORIQUE_PAR_PATTERN[$label]}"
        done
        echo "Total historical: $NB_FUITES_HISTORIQUE occurrence(s)."
    fi
    echo
fi

# ── Structural check: /opt/argus install sanity (F1-equivalent) ──────────
# Not a leak check — a smoke test that the package's own scripts are at
# least syntactically valid and executable, if installed on this machine.
echo "--- /opt/argus install sanity ---"
DEST="/opt/argus"
NB_ECHECS=0
if [ ! -d "$DEST" ]; then
    echo "SKIP — $DEST absent (not installed on this machine)"
else
    for f in "$DEST"/*.sh; do
        [ -e "$f" ] || continue
        if bash -n "$f" 2>/dev/null; then
            echo "OK   — syntax: $(basename "$f")"
        else
            echo "FAIL — syntax: $(basename "$f")"
            NB_ECHECS=$((NB_ECHECS + 1))
        fi
        if [ ! -x "$f" ]; then
            echo "FAIL — not executable: $(basename "$f")"
            NB_ECHECS=$((NB_ECHECS + 1))
        fi
    done
    if [ "$NB_ECHECS" -gt 0 ]; then
        echo "$NB_ECHECS installed-script check(s) failed — publication BLOCKED."
        NB_FUITES=$((NB_FUITES + NB_ECHECS))
    fi
fi
echo

echo "=== Summary ==="
if [[ $NB_FUITES -eq 0 ]]; then
    echo "OK — no leak, install sanity passed. Publication possible."
else
    echo "LEAKS by pattern:"
    for label in "${!FUITES_PAR_PATTERN[@]}"; do
        printf "  %-30s %s occurrences\n" "$label" "${FUITES_PAR_PATTERN[$label]}"
    done
    echo
    echo "Total: $NB_FUITES occurrence(s) — publication BLOCKED."
fi

if [[ $NB_FUITES -eq 0 && $NB_FUITES_HISTORIQUE -eq 0 ]]; then
    exit 0
fi
exit 1
