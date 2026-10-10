# chart-daily.gp — trace l'historique quotidien du nombre d'attaques en PNG
# 4K (taille configurable). Gabarit statique : le terminal, les libellés
# (ARGUS_TITRE/XLABEL/YLABEL, traduits) et le chemin de sortie viennent de
# variables d'environnement posées par chart-daily.sh, qui génère aussi la
# partie dynamique (styles de ligne et commande plot, une par série réelle
# trouvée cette année, couleur résolue par nom et non par ordre de découverte :
# une série garde la même couleur d'une année sur l'autre).

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
