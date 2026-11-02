---
title: ARGUS
section: 7
header: Argus
---

# NAME

argus - zählt die Angriffe gegen einen Server und bewahrt ihren Verlauf als Diagramme auf

# BESCHREIBUNG

Kein Dauerdienst, keine Datenbank, geeignet für Maschinen mit weniger als 1 GB RAM.

Argus zählt die SSH-Angriffe eines Servers und, wenn sie installiert sind, die Sperren von Fail2Ban und CrowdSec. Ein Cron-Job läuft jede Nacht, schreibt reine Textdateien und zeichnet Diagramme. Zwischen zwei Nächten läuft nichts.
Argus speichert oder zeigt nie die IP-Adresse eines Angreifers, nur Anzahlen pro Stunde und pro Tag. Ein Angriff ist eine Quell-IP, die innerhalb eines Tages **ARGUS_SSH_THRESHOLD** fehlgeschlagene Authentifizierungsversuche erreicht.

Grafana ist eine kontinuierliche Ansicht einer Infrastruktur: ein Dienst, der ständig läuft und live abgefragt werden kann. Argus ist eine periodische Momentaufnahme des Sicherheitsverlaufs: ein Bild pro Nacht, gelesen, wann Sie wollen.

# ZWEI SCHRITTE

Das Paket wird auf dem **Server** installiert, der angegriffenen Maschine, nicht auf dem Arbeitsplatzrechner (dem Computer, an dem Sie lesen).

1. Auf dem Server zählt das Paket die Angriffe und zeichnet jede Nacht die Diagramme.
2. Auf dem Arbeitsplatzrechner kopiert **argus-fetch**(1) die Bilder von den Servern auf den Computer, an dem Sie sie lesen.

**argus-chart**(1) zeichnet andere Ansichten derselben Daten, auf dem Server.

# DATEIEN

*/opt/argus/*
:   Die Skripte: *collect-ssh.sh*, *collect-fail2ban.sh*, *collect-crowdsec.sh*, *chart-daily.sh*, *chart-period.sh*, *chart-hourly.sh*, *argus-lib.sh*, *argus-doctor.sh*.

*/etc/argus/argus.conf*
:   Optionale Einstellungen, eine Shell-Datei, die von jedem Skript gelesen wird. Jede Zeile ist auskommentiert.

*/etc/cron.d/argus*
:   Sammlung um 00:05, Diagramme um 00:15, Gesundheitsprüfung um 00:20.

`/srv/argus/<year>/<series>_<year>.txt`
:   Eine Zeile pro Stunde mit einem Angriff, **\<count\> \<YYYY-MM-DD\>T\<HH\>**. Eine Serie ist der Dateiname ohne das Jahr: *ssh_direct*, *ip_ban_\<jail\>*.

`/srv/argus/<year>/.heartbeat/`
:   Eine Zeile pro Tag und Sammler, gelesen von *argus-doctor.sh*.

`/srv/argus/<year>/images/`
:   Die PNG-Diagramme.

*/var/log/argus.log*
:   Ausgabe der Cron-Jobs.

# UMGEBUNG

Die Variablen werden in */etc/argus/argus.conf* gesetzt. Eine Variable, die bereits in der Umgebung gesetzt ist, hat Vorrang vor der Datei.

**ARGUS_DATA_DIR**
:   Daten und Bilder. Standard */srv/argus*.

**ARGUS_SSH_THRESHOLD**
:   Fehlgeschlagene Versuche einer IP an einem Tag, die einen Angriff ausmachen. Standard 5.

**ARGUS_AUTHLOG**
:   SSH-Protokoll. Standard */var/log/auth.log*; wenn es nicht existiert, wird das Journal gelesen.

**ARGUS_SSHD_UNIT**
:   systemd-Unit, die aus dem Journal gelesen wird. Standard *ssh*.

**ARGUS_FAIL2BAN_LOG**
:   Fail2Ban-Protokoll. Standard */var/log/fail2ban.log*.

**ARGUS_DATA_OWNER**
:   Benutzer, dem die Dateien nach jedem Schreiben gehören.

**ARGUS_LANG**
:   Sprache der Diagramme: *en* (Standard), *fr*, *de* oder *es*.

**ARGUS_IMG_WIDTH**, **ARGUS_IMG_HEIGHT**
:   Bildgröße in Pixeln. Standard 3840 und 2160.

**ARGUS_COULEUR_**`<series>`
:   Farbe einer Serie, jeder gnuplot-Farbname. Im Namen der Variablen werden Bindestriche der Serie zu Unterstrichen.

**ARGUS_CONF**
:   Pfad der Konfigurationsdatei statt */etc/argus/argus.conf*.

# BEISPIELE

Prüfen Sie, ob jeder Sammler gestern lief:

```sh
sudo /opt/argus/argus-doctor.sh
```


Zeichnen Sie die Anzahl des vierten Quartals 2026 als ein Diagramm:

```sh
sudo argus-chart period --quarter 2026-Q4
```


# SIEHE AUCH

**argus-chart**(1), **argus-fetch**(1)
