# Spécification du répertoire contenant les fichiers .txt
#repertoire = "$HOME/$(date +%Y)"
repertoire = system("date +%Y | tr -d '\n'")

# Définir la variable de sortie
output_date = system("date +%F | tr -d '\n'")

# Spécification du fichier de sortie
set output sprintf("%s/images/%s_ip_ban_fail2ban_4k.png", repertoire, output_date)


# Paramètres du graphique
set title "Nombre d'adresses IP bannies par jour" textcolor rgb "white"
set xlabel 'Date' textcolor rgb "white"
set ylabel "Nombre d'adresses IP bannies" textcolor rgb "white"
set xtics textcolor rgb "gray60"
set ytics textcolor rgb "gray60"
set border linecolor rgb "gray30"
set key textcolor rgb 'white'

# Format de date
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xdata time

# Définition des styles de ligne
set style line 1 lc rgb "white"  
set style line 2 lc rgb "yellow" 
set style line 3 lc rgb "blue"  
set style line 4 lc rgb "purple" 
set style line 5 lc rgb "green" 
set style line 6 lc rgb "red" 
set style line 7 lc rgb "orange"
set style line 8 lc rgb "gold"
set style line 9 lc rgb "white"
set style line 10 lc rgb "violet"
set style line 11 lc rgb "brown"
set style line 12 lc rgb "magenta"
set style line 13 lc rgb "pink"
set style line 14 lc rgb "cyan"
set style line 15 lc rgb "turquoise"

# Agrandissement de la légende
set key width 4 height 2 font ",16"

plot for [idx=1:int(system('find '.repertoire.' -name "ip_ban_*.txt" -type f -size +0c | wc -l'))] \
    word(system('find '.repertoire.' -name "ip_ban_*.txt" -type f -size +0c'), idx) \
    using 2:1 with linespoints ls (idx % 14) + 1 title sprintf("'%s'", system('basename -s .txt "$(find '.repertoire.' -name "ip_ban_*.txt" -type f -size +0c | sed -n '.idx.'p)" | tr "_" " "'))
