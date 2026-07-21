#!/bin/bash
# plot.sh — aggregates the hourly-bucketed files produced by collect-ssh.sh
# and collect-fail2ban.sh into daily totals, then calls plot.gp to render the
# chart. Kept as a thin wrapper on purpose: plot.gp itself stays close to the
# original 2024 rendering script (proven, unchanged plotting logic) — only
# this daily aggregation step is new, made necessary by the hourly storage
# format (see SPECIFICATIONS/V1_0_0_PUBLICATION.md).
set -Eeuo pipefail

CONF="/etc/argus/argus.conf"
[ -f "$CONF" ] && . "$CONF"

DATA_DIR="${ARGUS_DATA_DIR:-/srv/argus}"
YEAR="${1:-$(date +%Y)}"

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
    echo "plot.sh: no data file for $YEAR in $annee_dir — nothing to plot." >&2
    exit 0
fi

for f in "${fichiers[@]}"; do
    base="$(basename "$f")"
    gawk '{split($2, a, "T"); c[a[1]] += $1} END {for (d in c) print c[d], d}' "$f" \
        | sort -k2,2 > "$daily_dir/$base"
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARGUS_YEAR_DIR="$daily_dir" ARGUS_IMAGES_DIR="$images_dir" \
    gnuplot "$SCRIPT_DIR/plot.gp"

# Le PNG vient d'être créé par gnuplot (root, via cron) — appliquer les mêmes
# droits que le reste de l'arborescence, sinon il reste 644 root:root même
# quand ARGUS_DATA_OWNER est renseigné.
chmod 644 "$images_dir"/*.png 2>/dev/null || true
if [ -n "${ARGUS_DATA_OWNER:-}" ]; then
    chown "$ARGUS_DATA_OWNER" "$images_dir"/*.png 2>/dev/null || true
fi
