# Argus

<p align="center">
  <a href="https://github.com/RonanDavalan/Argus/releases/latest"><img src="https://img.shields.io/github/v/release/RonanDavalan/Argus?label=version" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Debian_%C2%B7_Ubuntu-informational.svg" alt="Debian and Ubuntu">
  <img src="https://img.shields.io/badge/Shell-Bash_%C2%B7_gnuplot-lightgrey.svg" alt="Bash and gnuplot">
</p>

[English](README.md) | [Français](README.fr.md) | **Deutsch** | [Español](README.es.md)

<p align="center">
  <a href="https://argus.davalan.fr/images/argus-daily-4k.png"><img src="https://argus.davalan.fr/images/argus-daily-1600.jpg" alt="Argus: Tagesdiagramm der Angriffe pro Serie, eine Linie für SSH, Fail2Ban und CrowdSec" width="800"></a>
</p>

Kein Dauerdienst, keine Datenbank, geeignet für Maschinen mit weniger als 1 GB RAM.

Argus zählt die Angriffe gegen Ihre Server, SSH von selbst und, wenn sie installiert sind, die Sperren von Fail2Ban und CrowdSec, und bewahrt den Verlauf als Diagramme auf. Ein Cron-Job läuft jede Nacht, schreibt reine Textdateien und zeichnet die Diagramme. Zwischen zwei Nächten läuft nichts.

Argus speichert oder zeigt nie die IP-Adresse eines Angreifers, nur Anzahlen pro Stunde und pro Tag. Ein **Angriff** ist eine Quell-IP, die innerhalb eines Tages eine Mindestzahl fehlgeschlagener Authentifizierungsversuche erreicht (standardmäßig 5), damit ein falsch getipptes Passwort nicht zählt.

Grafana ist eine kontinuierliche Ansicht einer Infrastruktur: ein Dienst, der ständig läuft und live abgefragt werden kann. Argus ist eine periodische Momentaufnahme Ihrer Sicherheitshistorie: ein Bild pro Nacht, gelesen, wann Sie wollen. Grafana kann auch nach Woche oder Jahr aggregieren, zum Preis eines Dauerdienstes, einer Zeitreihendatenbank und eines zu bauenden Dashboards; Argus hat keines der drei, weshalb es auf einen Server mit 1 GB passt.

## Installation in zwei Schritten

Wenn Sie ein Programm normalerweise auf dem Computer installieren, an dem Sie arbeiten, ist es hier umgekehrt. Das Paket kommt auf den **Server**, die angegriffene Maschine. Ihr eigener Computer, der Arbeitsplatzrechner, installiert nichts aus dem Paket und empfängt nur die Bilder.

1. **Auf dem Server** (der angegriffenen Maschine) installieren Sie das Paket. Es zählt die Angriffe und zeichnet jede Nacht die Diagramme. Danach ist nichts zu starten.
2. **Auf Ihrem Arbeitsplatzrechner** (dem Computer, an dem Sie lesen) führen Sie `argus-fetch` aus. Es kopiert die Diagrammbilder von Ihren Servern auf Ihren Computer.

Wo jeder Teil liegt:

```
server.example.org (the server)           your desk
─────────────────────────────────         ──────────────────────────────
/opt/argus/        scripts                ~/.config/argus/hosts.conf
/etc/argus/        argus.conf                 the list of your servers
/srv/argus/<year>/ data and images        ~/argus-backup/<server>/<year>/images/
/usr/bin/argus-chart                          the copied charts
/usr/bin/argus-fetch   ── copies images ──►
```


Schritt 1, auf dem Server (Debian oder Ubuntu):

```bash
sudo apt install ./argus_1.0.0-13_all.deb
```


Schritt 2, auf Ihrem Arbeitsplatzrechner. Tragen Sie Ihre Server in die Datei `~/.config/argus/hosts.conf` ein, einen pro Zeile, in der Form `<ssh alias>,<data directory>`, und führen Sie dann `argus-fetch` aus:

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


`argus-fetch` wird vom selben Paket installiert. Auf einem Rechner, der keine Debian-Maschine ist, kopieren Sie das einzelne Skript `argus-fetch` aus diesem Repository; es braucht nur `bash`, `ssh` und `rsync`. Einzelheiten: [docs/install.md](docs/de/install.md) und [docs/desk.md](docs/de/desk.md).

## Die drei Ansichten

`argus-chart` zeichnet ein Diagramm für das Zeitfenster, das Sie wählen. Führen Sie es auf dem Server aus. Jeder Befehl schreibt ein PNG in `/srv/argus/<year>/images/` (mit `--out DIR` schreiben Sie woandershin, was ein gewöhnlicher Benutzer braucht).

- `argus-chart daily` ist der Verlauf des Jahres, ein Punkt pro Tag.
- `argus-chart period` ist die Anzahl jeder Serie über ein Zeitfenster.
- `argus-chart hourly` ist die Anzahl pro Stunde des Tages über ein Zeitfenster, von 00 bis 23.

Zehn Zeitfenster zum Kopieren:

```bash
argus-chart period --day 2026-10-30                       # one day, one point per hour
argus-chart period --week 2026-W44                        # ISO week, Monday to Sunday
argus-chart period --month 2026-10                        # one calendar month
argus-chart period --quarter 2026-Q4                      # one quarter
argus-chart period --year 2025                            # one year
argus-chart period --from 2025-12-01 --to 2026-01-31      # a range over two years
argus-chart period --month 2026-10 --split week           # one PNG per week of the month
argus-chart period --week 2026-W44 --series ssh_direct    # one series only
argus-chart hourly --week 2026-W44                        # which hours are attacked
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd
```


Die Serien werden nebeneinander gezeichnet, nie addiert: SSH, jedes Fail2Ban-Jail und jedes CrowdSec-Szenario behalten ihre eigene Linie und Farbe. Einzelheiten: [docs/charts.md](docs/de/charts.md).

## Eine Verbindung pro Host, kein erneuter Versuch

`argus-fetch` öffnet **eine Verbindung pro Host** und **versucht nie erneut**. Viele Server sperren eine Adresse nach einigen fehlgeschlagenen Anmeldungen, sodass ein zweiter Versuch Sie aussperren könnte. Ein Host, der nicht antwortet, wird einmal gemeldet, die anderen Hosts werden trotzdem kopiert, und der Exit-Code ist 1. Beheben Sie die Ursache (Schlüssel, Alias, Firewall, ausgeschaltete Maschine), und führen Sie den Befehl dann von Hand erneut aus.

## Konfiguration

Alles funktioniert mit den Standardwerten. Um einen zu ändern, bearbeiten Sie `/etc/argus/argus.conf` auf dem Server; die Datei wird von jedem Skript gelesen und enthält jeden Wert auskommentiert:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=5          # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_DATA_DIR="/srv/argus"    # where the data and the images are written
```


Die anderen Variablen (Protokollpfade, Bildgröße, Serienfarben) sind in `man argus` aufgeführt.

## Prüfen, ob es funktioniert

```bash
sudo /opt/argus/argus-doctor.sh
```


Es sagt, ob jede Quelle (SSH, Fail2Ban, CrowdSec) gestern gesammelt wurde. Siehe [docs/troubleshooting.md](docs/de/troubleshooting.md).

## Dokumentation

- [docs/install.md](docs/de/install.md): Installation auf dem Server, Aufbau, Deinstallation
- [docs/desk.md](docs/de/desk.md): die Diagramme auf den Arbeitsplatzrechner holen und lesen
- [docs/charts.md](docs/de/charts.md): Zeitfenster, Aufteilung, Stunde, Serien, Zeitzone, `T00`-Zeitscheiben
- [docs/troubleshooting.md](docs/de/troubleshooting.md): was `argus-doctor.sh` sagt und was zu tun ist
- Handbuchseiten: `man argus`, `man argus-chart`, `man argus-fetch` (Quellen in `man/en/`)

---

## Credits

Argus ist das Ergebnis einer Zusammenarbeit zwischen einem Menschen und mehreren Sprachmodellen, wobei die Rollen so festgehalten sind, wie sie tatsächlich gespielt wurden. Die vollständige Liste steht in [CONTRIBUTORS.md](CONTRIBUTORS.md).

*   **Ronan Davalan** – Architekt und Schiedsrichter: ursprüngliche Skripte (2024), Entscheidungen, Validierung und Tests.
*   **Claude Code (Anthropic)** – Leitender Entwickler: Sammler, Diagrammrendering, `argus-doctor.sh`, Debian-Paket, Dokumentation.
*   **Gemini (Google)** – Synthesizer und strategischer Co-Autor: Planung und Rahmung des Projektzwecks.
*   **Gemini (Google), GLM-5.3-Flash Free und Gemini 4 Argon** – Grafiker: visuelle Identität des Projekts (Marke, Icon, Favicon), von Ronan Davalan am 2026-11-02 übernommen.
*   **DeepSeek** – Begleiter im Feld: CrowdSec-Einrichtung auf einem echten Server, der zur Validierung von `collect-crowdsec.sh` diente.
*   **DeepSeek Flash** – Inhalt der Website auf Englisch, danach die französische, deutsche und spanische Übersetzung der Dokumentation, der Handbuchseiten und der Website.
*   **Muse Spark 1.3 Contributor** – Gestaltung der Website: Einbindung des Logos, des Favicons und des Diagrammbilds.
*   **gd2:** Ronan Davalans verstorbener Bruder. Er brachte Ronan Git und dessen Gebrauch bei, beriet bei diesem Projekt und nahm die erste externe Änderung an dessen README vor (2024-08-07).

---

## Lizenz

MIT – siehe `LICENSE`.
