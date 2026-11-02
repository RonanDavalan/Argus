# chart-period.gp — gabarit gnuplot de la vue par période : terminal, libellés
# et format de l'axe du temps viennent de variables d'environnement posées par
# chart-period.sh, qui envoie ensuite sur l'entrée standard le bloc de données
# et la commande plot (une ligne par série, couleur résolue par nom).

fichier = system("echo -n \"$ARGUS_OUT_FILE\"")
largeur = system("echo -n \"$ARGUS_IMG_WIDTH\"") + 0
hauteur = system("echo -n \"$ARGUS_IMG_HEIGHT\"") + 0

set terminal pngcairo size largeur,hauteur background rgb "gray10"
set output fichier

set title system("echo -n \"$ARGUS_TITRE\"") textcolor rgb "white"
set xlabel system("echo -n \"$ARGUS_XLABEL\"") textcolor rgb "white"
set ylabel system("echo -n \"$ARGUS_YLABEL\"") textcolor rgb "white"
set xtics textcolor rgb "gray60"
set ytics textcolor rgb "gray60"
set border linecolor rgb "gray30"
set key textcolor rgb "white" width 4 height 2 font ",16"
set yrange [0:*]

set xdata time
set timefmt system("echo -n \"$ARGUS_TIMEFMT\"")
set format x system("echo -n \"$ARGUS_XFORMAT\"")
