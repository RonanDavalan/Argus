# Graphiques : fenêtres, découpage, heure, séries

`argus-chart` a trois vues. Lancez-le sur le serveur, en root pour écrire dans `/srv/argus/<year>/images/`, ou en tant qu'utilisateur ordinaire avec `--out DIR`.

```
argus-chart daily  [YEAR]               one point per day, the whole year
argus-chart period [window] [options]   one line per series over a window
argus-chart hourly [window] [options]   24 positions, 00 to 23, per series
```


Chaque fichier est nommé `<today>_argus_<view>_<window>.png`, par exemple `2026-11-02_argus_period_week-2026-W44.png`.

## Fenêtres

`period` et `hourly` acceptent les mêmes fenêtres. Sans fenêtre, ils utilisent l'année en cours.

| Option | Fenêtre | Exemple |
|---|---|---|
| `--day YYYY-MM-DD` | un jour | `--day 2026-10-30` |
| `--week YYYY-Www` | semaine ISO, du lundi au dimanche | `--week 2026-W44` |
| `--month YYYY-MM` | mois calendaire | `--month 2026-10` |
| `--quarter YYYY-Qn` | trimestre, `n` de 1 à 4 | `--quarter 2026-Q4` |
| `--year YYYY` | année calendaire | `--year 2025` |
| `--from D --to D` | plage, les deux jours inclus | `--from 2025-12-01 --to 2026-01-31` |

Les semaines suivent la norme ISO 8601 : la semaine 1 de 2027 commence le lundi 2027-01-04, et 2026 compte une semaine 53. Une fenêtre qui couvre deux années lit les données des deux.

```bash
argus-chart period --day 2026-10-30 --out ~/argus-out
argus-chart period --from 2025-12-01 --to 2026-01-31 --out ~/argus-out
```


## Découper une longue fenêtre

`--split` dessine un graphique par sous-période au lieu d'un seul long graphique :

```bash
argus-chart period --month 2026-10 --split week --out ~/argus-out
argus-chart period --year 2026 --split month --out ~/argus-out
```


`--split week` convient à un mois ou à un trimestre, `--split month` à un trimestre ou à une année. La première commande écrit un fichier par semaine ISO touchant octobre, chacun découpé à la fenêtre, nommé `…_month-2026-10_week-2026-W41.png`.

## L'heure de la journée

`hourly` additionne, pour chaque série, les attaques vues à chaque heure sur la fenêtre, et dessine 24 positions. Il montre à quelles heures de la journée vous êtes attaqué, et non quels jours.

```bash
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


L'heure est l'**heure locale du serveur**, telle que l'écrivent les collecteurs. C'est l'heure à laquelle l'attaque a été vue dans les journaux, non l'heure à laquelle elle a commencé. Le titre indique « local server time ». Un changement d'heure d'été ajoute ou retire une heure sur une journée ; sur une semaine ou plus, l'effet ne se voit pas.

## Séries

Une série est une ligne : `ssh_direct` pour SSH, `ip_ban_<jail>` pour chaque jail Fail2Ban, `ip_ban_<scenario>` pour chaque scénario CrowdSec. Le nom est celui du fichier de données sans l'année, donc `ssh_direct_2026.txt` est la série `ssh_direct`.

Les séries sont superposées, jamais additionnées : Argus n'invente pas un score à partir d'outils différents. Chaque série garde la même couleur d'une année à l'autre (définissez-la avec `ARGUS_COULEUR_<series>`, sinon elle vient d'un hachage du nom).

```bash
argus-chart period --week 2026-W44 --list-series
argus-chart period --week 2026-W44 --series ssh_direct
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd --out ~/argus-out
```


Un nom inconnu dans `--series` arrête la commande avec le code de sortie 2 et liste les noms disponibles.

## Lire les nombres au lieu de l'image

`--print-data` imprime sur la sortie standard le tableau qui sous-tend le graphique (séparé par des tabulations, en-tête commençant par `#`) et ne dessine rien :

```bash
argus-chart period --week 2026-W44 --print-data
argus-chart hourly --day 2026-10-30 --print-data
```


## Tranches à l'heure 00 (`T00`)

Une ligne de données est `<count> <date>T<hour>`, par exemple `492 2026-10-30T14`. Les fichiers antérieurs à la collecte horaire contiennent une ligne par jour, toutes écrites en `T00`. Une série composée uniquement de tranches `T00` n'a aucune information d'heure, si bien que `hourly` l'écarte au lieu de dessiner une barre à minuit. Il imprime le message `series 'legacy' excluded: all its slices are at hour 00 (daily data, no hourly depth)` sur la sortie d'erreur et écrit `excluded series: no hourly data: legacy` dans le titre du graphique. `period` et `daily` le dessinent encore, comme points quotidiens.

## Langue des graphiques

`ARGUS_LANG` définit les titres et les axes : `en` (par défaut), `fr`, `de` ou `es`.

```bash
ARGUS_LANG=de argus-chart period --week 2026-W44 --out ~/argus-out
```

