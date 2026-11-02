---
title: ARGUS-CHART
section: 1
header: Argus
---

# NAME

argus-chart - zeichnet die Argus-Diagramme eines Servers

# ÜBERSICHT

**argus-chart period** [*Zeitfenster*] [*Optionen*]

**argus-chart hourly** [*Zeitfenster*] [*Optionen*]

**argus-chart daily** [*Jahr*]

**argus-chart** {**-h**|**--help**}

# BESCHREIBUNG

**argus-chart** ist der einzige Einstiegspunkt der Diagramme. Es übergibt die Optionen nach dem Ansichtsnamen unverändert an das Skript dieser Ansicht, das neben dem Befehl und dann in */opt/argus* gesucht wird. Führen Sie es auf dem Server aus, als root, um in */srv/argus* zu schreiben, oder als gewöhnlicher Benutzer mit **--out**.

**period**
:   Die Anzahl jeder Serie über ein Zeitfenster, eine Linie pro Serie. Skript *chart-period.sh*.

**hourly**
:   Die Anzahl jeder Serie zu jeder Stunde des Tages, 00 bis 23, über ein Zeitfenster addiert. Die Stunde ist die lokale Serverzeit. Skript *chart-hourly.sh*.

**daily**
:   Der Verlauf eines Jahres, ein Punkt pro Tag, standardmäßig das laufende Jahr. Skript *chart-daily.sh*.

Die Serien werden übereinandergelegt, nie addiert.

# ZEITFENSTER

Eines der folgenden, für **period** und **hourly**. Ohne eines ist das Zeitfenster das laufende Jahr. Ein Zeitfenster, das zwei Jahre umfasst, liest die Daten beider.

**--day** *YYYY-MM-DD*
:   Ein Tag.

**--week** *YYYY-Www*
:   Eine ISO-8601-Woche, Montag bis Sonntag.

**--month** *YYYY-MM*
:   Ein Kalendermonat.

**--quarter** *YYYY-Qn*
:   Ein Quartal, *n* von 1 bis 4.

**--year** *YYYY*
:   Ein Kalenderjahr.

**--from** *YYYY-MM-DD* **--to** *YYYY-MM-DD*
:   Ein Zeitraum, beide Tage eingeschlossen.

# OPTIONEN

**--series** *a,b*
:   Nur diese Serien, ohne Jahressuffix benannt. Ein unbekannter Name stoppt den Befehl mit dem Exit-Status 2.

**--list-series**
:   Gibt die Serien des Zeitfensters aus und beendet. Mit **hourly** nur die Serien, die gezeichnet werden.

**--split** *week*|*month*
:   Nur **period**. Ein Diagramm pro ISO-Woche oder pro Kalendermonat des Zeitfensters. Unterzeiträume werden auf das Zeitfenster zugeschnitten.

**--out** *DIR*
:   Ausgabeverzeichnis. Standard `/srv/argus/<year>/images`.

**--print-data**
:   Gibt die Tabelle hinter dem Diagramm auf der Standardausgabe aus, tabgetrennt, Kopfzeile beginnend mit **#**, und beendet. Nichts wird gezeichnet.

**-h**, **--help**
:   Gibt die Verwendung aus und beendet. Nach einem Ansichtsnamen werden die Optionen dieser Ansicht ausgegeben.

# DATEIEN

`<out>/<YYYY-MM-DD>_argus_<view>_<window>.png`
:   Das Diagramm. Das Datum ist heute; das Zeitfenster ist zum Beispiel *week-2026-W44*, *month-2026-10* oder *range-2025-12-01_2026-01-31*. Mit **--split** ist es `<parent>_<sub-period>`, zum Beispiel *month-2026-10_week-2026-W41*.

# RÜCKGABEWERTE

**0**
:   Erledigt.

**2**
:   Eine falsche Verwendung, eine unbekannte Serie oder eine Ansicht, die diese Version nicht hat.

Jeder andere Status ist der des ausgeführten Skripts.

# BEISPIELE

Eine Woche, dann dieselbe Woche nach Stunde:

```sh
argus-chart period --week 2026-W44 --out ~/argus-out
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


Ein Diagramm pro Woche eines Monats, nur für SSH:

```sh
argus-chart period --month 2026-10 --split week --series ssh_direct --out ~/argus-out
```


# SIEHE AUCH

**argus**(7), **argus-fetch**(1)
