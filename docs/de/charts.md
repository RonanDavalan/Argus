# Diagramme: Zeitfenster, Aufteilung, Stunde, Serien

`argus-chart` hat drei Ansichten. Führen Sie es auf dem Server aus, als root, um in `/srv/argus/<year>/images/` zu schreiben, oder als gewöhnlicher Benutzer mit `--out DIR`.

```
argus-chart daily  [YEAR]               one point per day, the whole year
argus-chart period [window] [options]   one line per series over a window
argus-chart hourly [window] [options]   24 positions, 00 to 23, per series
```


Jede Datei heißt `<today>_argus_<view>_<window>.png`, zum Beispiel `2026-11-02_argus_period_week-2026-W44.png`.

## Zeitfenster

`period` und `hourly` nehmen dieselben Zeitfenster. Ohne eines verwenden sie das laufende Jahr.

| Option | Zeitfenster | Beispiel |
|---|---|---|
| `--day YYYY-MM-DD` | ein Tag | `--day 2026-10-30` |
| `--week YYYY-Www` | ISO-Woche, Montag bis Sonntag | `--week 2026-W44` |
| `--month YYYY-MM` | Kalendermonat | `--month 2026-10` |
| `--quarter YYYY-Qn` | Quartal, `n` von 1 bis 4 | `--quarter 2026-Q4` |
| `--year YYYY` | Kalenderjahr | `--year 2025` |
| `--from D --to D` | Zeitraum, beide Tage eingeschlossen | `--from 2025-12-01 --to 2026-01-31` |

Wochen folgen ISO 8601: Woche 1 des Jahres 2027 beginnt am Montag, 2027-01-04, und 2026 hat eine Woche 53. Ein Zeitfenster, das zwei Jahre umfasst, liest die Daten beider.

```bash
argus-chart period --day 2026-10-30 --out ~/argus-out
argus-chart period --from 2025-12-01 --to 2026-01-31 --out ~/argus-out
```


## Ein langes Zeitfenster aufteilen

`--split` zeichnet ein Diagramm pro Unterzeitraum statt eines einzigen langen Diagramms:

```bash
argus-chart period --month 2026-10 --split week --out ~/argus-out
argus-chart period --year 2026 --split month --out ~/argus-out
```


`--split week` eignet sich für einen Monat oder ein Quartal, `--split month` für ein Quartal oder ein Jahr. Der erste Befehl schreibt eine Datei pro ISO-Woche, die Oktober berührt, jede auf das Zeitfenster zugeschnitten, benannt `…_month-2026-10_week-2026-W41.png`.

## Die Stunde des Tages

`hourly` addiert für jede Serie die Angriffe, die zu jeder Stunde im Zeitfenster gesehen wurden, und zeichnet 24 Positionen. Es zeigt, zu welchen Stunden des Tages Sie angegriffen werden, nicht an welchen Tagen.

```bash
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


Die Stunde ist die **lokale Serverzeit**, wie die Sammler sie schreiben. Es ist die Stunde, zu der der Angriff in den Protokollen gesehen wurde, nicht die Stunde seines Beginns. Der Titel sagt „local server time“. Eine Zeitumstellung fügt an einem Tag eine Stunde hinzu oder entfernt sie; über eine Woche oder mehr zeigt sich der Effekt nicht.

## Serien

Eine Serie ist eine Linie: `ssh_direct` für SSH, `ip_ban_<jail>` für jedes Fail2Ban-Jail, `ip_ban_<scenario>` für jedes CrowdSec-Szenario. Der Name ist der Dateiname ohne das Jahr, also ist `ssh_direct_2026.txt` die Serie `ssh_direct`.

Die Serien werden übereinandergelegt, nie addiert: Argus erfindet keine Punktzahl aus verschiedenen Werkzeugen. Jede Serie behält dieselbe Farbe von Jahr zu Jahr (legen Sie sie mit `ARGUS_COULEUR_<series>` fest, sonst stammt sie aus einem Hash des Namens).

```bash
argus-chart period --week 2026-W44 --list-series
argus-chart period --week 2026-W44 --series ssh_direct
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd --out ~/argus-out
```


Ein unbekannter Name in `--series` stoppt den Befehl mit dem Exit-Code 2 und listet die verfügbaren Namen auf.

## Die Zahlen statt des Bildes lesen

`--print-data` gibt die Tabelle hinter dem Diagramm auf der Standardausgabe aus (tabgetrennt, Kopfzeile beginnend mit `#`) und zeichnet nichts:

```bash
argus-chart period --week 2026-W44 --print-data
argus-chart hourly --day 2026-10-30 --print-data
```


## Zeitscheiben um 00 Uhr (`T00`)

Eine Datenzeile ist `<count> <date>T<hour>`, zum Beispiel `492 2026-10-30T14`. Dateien von vor der stündlichen Sammlung enthalten eine Zeile pro Tag, alle als `T00` geschrieben. Eine Serie, die nur aus `T00`-Zeitscheiben besteht, hat keine Stundeninformation, daher lässt `hourly` sie aus, statt einen Balken um Mitternacht zu zeichnen. Es gibt die Meldung `series 'legacy' excluded: all its slices are at hour 00 (daily data, no hourly depth)` auf der Fehlerausgabe aus und schreibt `excluded series: no hourly data: legacy` in den Titel des Diagramms. `period` und `daily` zeichnen sie weiterhin als Tagespunkte.

## Diagrammsprache

`ARGUS_LANG` legt die Titel und die Achsen fest: `en` (Standard), `fr`, `de` oder `es`.

```bash
ARGUS_LANG=de argus-chart period --week 2026-W44 --out ~/argus-out
```

