# chart-hourly.gp — gabarit gnuplot de la vue horaire : terminal, libellés et
# axe des heures (0 à 23, abscisse numérique) viennent de variables
# d'environnement posées par chart-hourly.sh, qui envoie ensuite sur l'entrée
# standard le bloc de données et la commande plot (une ligne par série).

fichier = system("echo -n \"$ARGUS_OUT_FILE\"")
largeur = system("echo -n \"$ARGUS_IMG_WIDTH\"") + 0
hauteur = system("echo -n \"$ARGUS_IMG_HEIGHT\"") + 0

set terminal pngcairo size largeur,hauteur background rgb "gray10"
set output fichier

set title system("echo -n \"$ARGUS_TITRE\"") textcolor rgb "white"
set xlabel system("echo -n \"$ARGUS_XLABEL\"") textcolor rgb "white"
set ylabel system("echo -n \"$ARGUS_YLABEL\"") textcolor rgb "white"
set xtics 0,1,23 format "%02.0f" textcolor rgb "gray60"
set ytics textcolor rgb "gray60"
set border linecolor rgb "gray30"
set key textcolor rgb "white" width 4 height 2 font ",16"
set yrange [0:*]
set xrange [-0.5:23.5]
