---
title: ARGUS-CHART
section: 1
header: Argus
---

# NOM

argus-chart - dessine les graphiques Argus d'un serveur

# SYNOPSIS

**argus-chart period** [*fenêtre*] [*options*]

**argus-chart hourly** [*fenêtre*] [*options*]

**argus-chart daily** [*année*]

**argus-chart** {**-h**|**--help**}

# DESCRIPTION

**argus-chart** est le point d'entrée unique des graphiques. Il transmet les options qui suivent le nom de la vue, inchangées, au script de cette vue, cherché à côté de la commande puis dans */opt/argus*. Lancez-le sur le serveur, en root pour écrire dans */srv/argus*, ou en tant qu'utilisateur ordinaire avec **--out**.

**period**
:   Le compte de chaque série sur une fenêtre, une ligne par série. Script *chart-period.sh*.

**hourly**
:   Le compte de chaque série à chaque heure de la journée, de 00 à 23, additionné sur une fenêtre. L'heure est l'heure locale du serveur. Script *chart-hourly.sh*.

**daily**
:   L'historique d'une année, un point par jour, l'année en cours par défaut. Script *chart-daily.sh*.

Les séries sont superposées, jamais additionnées.

# FENÊTRE

L'une des fenêtres suivantes, pour **period** et **hourly**. Sans fenêtre, la fenêtre est l'année en cours. Une fenêtre qui couvre deux années lit les données des deux.

**--day** *YYYY-MM-DD*
:   Un jour.

**--week** *YYYY-Www*
:   Une semaine ISO 8601, du lundi au dimanche.

**--month** *YYYY-MM*
:   Un mois calendaire.

**--quarter** *YYYY-Qn*
:   Un trimestre, *n* de 1 à 4.

**--year** *YYYY*
:   Une année calendaire.

**--from** *YYYY-MM-DD* **--to** *YYYY-MM-DD*
:   Une plage, les deux jours inclus.

# OPTIONS

**--series** *a,b*
:   Seulement ces séries, nommées sans le suffixe d'année. Un nom inconnu arrête la commande avec le code de sortie 2.

**--list-series**
:   Imprime les séries de la fenêtre et quitte. Avec **hourly**, seulement les séries qui sont tracées.

**--split** *week*|*month*
:   **period** seulement. Un graphique par semaine ISO, ou par mois calendaire, de la fenêtre. Les sous-périodes sont découpées à la fenêtre.

**--out** *DIR*
:   Répertoire de sortie. Par défaut `/srv/argus/<year>/images`.

**--print-data**
:   Imprime sur la sortie standard le tableau qui sous-tend le graphique, séparé par des tabulations, ligne d'en-tête commençant par **#**, et quitte. Rien n'est dessiné.

**-h**, **--help**
:   Imprime l'usage et quitte. Après un nom de vue, imprime les options de cette vue.

# FICHIERS

`<out>/<YYYY-MM-DD>_argus_<view>_<window>.png`
:   Le graphique. La date est celle du jour ; la fenêtre est par exemple *week-2026-W44*, *month-2026-10* ou *range-2025-12-01_2026-01-31*. Avec **--split**, c'est `<parent>_<sub-period>`, par exemple *month-2026-10_week-2026-W41*.

# CODES DE SORTIE

**0**
:   Terminé.

**2**
:   Un usage incorrect, une série inconnue, ou une vue que cette version ne possède pas.

Tout autre code est celui du script qui a été exécuté.

# EXEMPLES

Une semaine, puis la même semaine par heure :

```sh
argus-chart period --week 2026-W44 --out ~/argus-out
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


Un graphique par semaine d'un mois, pour SSH seulement :

```sh
argus-chart period --month 2026-10 --split week --series ssh_direct --out ~/argus-out
```


# VOIR AUSSI

**argus**(7), **argus-fetch**(1)
