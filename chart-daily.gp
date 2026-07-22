# chart-daily.gp — renders the daily attack-count history as a 4K PNG
# (size configurable). Static template: terminal, labels (i18n via
# ARGUS_TITRE/XLABEL/YLABEL) and output path come from environment
# variables set by chart-daily.sh, which also generates and hands over
# the dynamic part (line styles + plot command, one per real series found
# this year, colour resolved by name — not by discovery position, so a
# given series keeps the same colour year after year).

images_dir = system("echo -n \"$ARGUS_IMAGES_DIR\"")
largeur = system("echo -n \"$ARGUS_IMG_WIDTH\"") + 0
hauteur = system("echo -n \"$ARGUS_IMG_HEIGHT\"") + 0
output_date = system("date +%F | tr -d '\n'")

set terminal pngcairo size largeur,hauteur background rgb "gray10"
set output sprintf("%s/%s_argus_4k.png", images_dir, output_date)

set title system("echo -n \"$ARGUS_TITRE\"") textcolor rgb "white"
set xlabel system("echo -n \"$ARGUS_XLABEL\"") textcolor rgb "white"
set ylabel system("echo -n \"$ARGUS_YLABEL\"") textcolor rgb "white"
set xtics textcolor rgb "gray60"
set ytics textcolor rgb "gray60"
set border linecolor rgb "gray30"
set key textcolor rgb "white"

set timefmt "%Y-%m-%d"
set format x "%b %d"
set xdata time

set key width 4 height 2 font ",16"

load system("echo -n \"$ARGUS_FRAGMENT\"")
