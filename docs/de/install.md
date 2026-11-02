# Argus auf dem Server installieren

Das Paket kommt auf den **Server**, die Maschine, deren Protokolle Argus liest. Sie installieren es nicht auf Ihrem Arbeitsplatzrechner: Der Arbeitsplatzrechner kopiert nur die Diagramme (siehe [desk.md](desk.md)).

## Was Sie erhalten

```
/opt/argus/
├── collect-ssh.sh         SSH attacks, from auth.log or journald
├── collect-fail2ban.sh    Fail2Ban bans, one series per jail (optional)
├── collect-crowdsec.sh    CrowdSec alerts, one series per scenario (optional)
├── chart-daily.sh         history of the year, one point per day
├── chart-period.sh        count over a window (day, week, month, quarter, year, range)
├── chart-hourly.sh        count per hour of the day over a window
├── chart-*.gp             the gnuplot drawing of each view
├── argus-lib.sh           code shared by the chart scripts
└── argus-doctor.sh        health check of the collection

/usr/bin/argus-chart       one command for the three views
/usr/bin/argus-fetch       copies the charts to a desk
/etc/argus/argus.conf      optional settings, every line commented out
/etc/cron.d/argus          the nightly jobs
/srv/argus/                data and charts, readable by everyone
└── 2026/
    ├── ssh_direct_2026.txt      one line per hour with an attack
    ├── ip_ban_sshd_2026.txt     one file per Fail2Ban jail, if present
    ├── .daily/                  daily totals, rebuilt by chart-daily.sh
    ├── .heartbeat/              daily proof that each collector ran
    └── images/                  the PNG charts
```


`/srv/argus/` enthält nur Anzahlen, nie eine IP-Adresse, ist also für jeden Benutzer lesbar: Sie kopieren die Diagramme ohne `sudo`.

## Voraussetzungen

Ein Debian- oder Ubuntu-Server mit Cron. Das Paket hängt von `gawk` und `gnuplot-nox` ab; `apt` installiert sie. `rsync` und `openssh-client` werden empfohlen (sie dienen `argus-fetch`). Fail2Ban, CrowdSec und `jq` sind optional. Ein Server mit 1 GB RAM genügt: Nichts bleibt laufen.

## Installation

Laden Sie `argus_1.0.0-11_all.deb` von der Release-Seite des Repositorys herunter und führen Sie dann auf dem Server aus:

```bash
sudo apt install ./argus_1.0.0-11_all.deb
```


Die Cron-Jobs beginnen in dieser Nacht: Sammlung um 00:05, Diagramme um 00:15, Gesundheitsprüfung um 00:20. Das erste Diagramm erscheint nach der ersten Nacht in `/srv/argus/2026/images/`.

## Jetzt ausprobieren

Um die erste Nacht zu überspringen, führen Sie die Schritte von Hand auf einem Server aus, der bereits einen Protokollverlauf hat:

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/chart-daily.sh
ls /srv/argus/2026/images/
```


Zeichnen Sie dann eine Ansicht:

```bash
sudo argus-chart period --month 2026-10
```


## Eine Einstellung ändern

`/etc/argus/argus.conf` ist eine Shell-Datei, die von jedem Skript gelesen wird. Entfernen Sie die Kommentarzeichen nur bei dem, was Sie brauchen:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=10         # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_IMG_WIDTH=3840           # image size in pixels
ARGUS_IMG_HEIGHT=2160
ARGUS_COULEUR_ssh_direct=orange   # colour of one series, any gnuplot colour name
```


Variablennamen verwenden Großbuchstaben und Unterstriche, nie Bindestriche. Die Serie `caddy-xmlrpc` wird daher durch `ARGUS_COULEUR_caddy_xmlrpc` gefärbt. Alle Variablen sind in `man argus` aufgeführt.

## Entfernen

```bash
sudo apt remove argus     # removes the scripts, keeps /srv/argus and /etc/argus
sudo apt purge argus      # also removes /srv/argus and /etc/argus
```


Purge löscht auch Ihren Verlauf. Kopieren Sie ihn zuerst mit `argus-fetch` (siehe [desk.md](desk.md)).
