# plot.gp — renders the daily attack-count history as a 4K PNG.
#
# Adapted from Argus's original 2024 script (fail2ban_gnuplot_couleur_4k.gp):
# same dynamic file discovery, same unlimited historical horizon, same
# multi-series rendering — the core mechanism that made Argus worth keeping
# is untouched. Only the input directory changed: this reads the daily
# totals pre-aggregated by plot.sh (env vars ARGUS_YEAR_DIR / ARGUS_IMAGES_DIR),
# never the raw hourly files written by collect-ssh.sh / collect-fail2ban.sh.

repertoire = system("echo -n \"$ARGUS_YEAR_DIR\"")
images_dir = system("echo -n \"$ARGUS_IMAGES_DIR\"")
output_date = system("date +%F | tr -d '\n'")

set terminal pngcairo size 3840,2160 background rgb "gray10"
set output sprintf("%s/%s_argus_4k.png", images_dir, output_date)

set title "Attacks per day" textcolor rgb "white"
set xlabel "Date" textcolor rgb "white"
set ylabel "Attack count" textcolor rgb "white"
set xtics textcolor rgb "gray60"
set ytics textcolor rgb "gray60"
set border linecolor rgb "gray30"
set key textcolor rgb "white"

set timefmt "%Y-%m-%d"
set format x "%b %d"
set xdata time

set style line 1 lc rgb "white"
set style line 2 lc rgb "purple" lw 2
set style line 3 lc rgb "green" lw 2
set style line 4 lc rgb "red" lw 2
set style line 5 lc rgb "orange" lw 2
set style line 6 lc rgb "gold"
set style line 7 lc rgb "white"
set style line 8 lc rgb "blue"
set style line 9 lc rgb "violet"
set style line 10 lc rgb "brown"
set style line 11 lc rgb "magenta"
set style line 12 lc rgb "yellow"
set style line 13 lc rgb "pink"
set style line 14 lc rgb "cyan"
set style line 15 lc rgb "turquoise"

set key width 4 height 2 font ",16"

plot for [idx=1:int(system('find "'.repertoire.'" -name "*.txt" -type f -size +0c | wc -l'))] \
    word(system('find "'.repertoire.'" -name "*.txt" -type f -size +0c'), idx) \
    using 2:1 with linespoints ls (idx % 14) + 1 title sprintf("%s", system('basename -s .txt "$(find "'.repertoire.'" -name "*.txt" -type f -size +0c | sed -n '.idx.'p)" | tr "_" " "'))
