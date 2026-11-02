# Fehlerbehebung

Ein Diagramm ohne Angriff kann einen ruhigen Tag oder einen Sammler bedeuten, der angehalten wurde. Die Datendateien können beide nicht unterscheiden, weil ein Tag ohne Angriff keine Zeile schreibt. `argus-doctor.sh` kann es: Jeder Sammler schreibt eine Zeile pro Tag in `/srv/argus/<year>/.heartbeat/<source>.txt`, `<date> <number of events>`, auch wenn die Zahl 0 ist.

## Die Prüfung ausführen

```bash
sudo /opt/argus/argus-doctor.sh
```


Der Cron-Job führt sie jede Nacht um 00:20 aus und hängt die Ausgabe an `/var/log/argus.log` an. Der Exit-Code ist 0, wenn nichts zu melden ist, sonst 1. Ein gesunder Server gibt aus:

```
== Source availability ==

== Heartbeats (2026) ==
  ssh : ok
    -> up to date, yesterday: 12 event(s)
  fail2ban : absent
  crowdsec : absent

Nothing to report.
```


## Was jede Zeile bedeutet

`<source> : ok` oder `absent` sagt, ob die Quelle jetzt gelesen werden kann: `auth.log` oder `journald` für `ssh`, `fail2ban-client` und sein Protokoll für `fail2ban`, `cscli` und `jq` für `crowdsec`. `absent` für Fail2Ban oder CrowdSec ist normal, wenn Sie sie nicht betreiben.

| Zeile unter der Quelle | Bedeutung | Was zu tun ist |
|---|---|---|
| `up to date, yesterday: N event(s)` | gestern gesammelt, N Ereignisse (0 ist ein ruhiger Tag) | nichts |
| `last confirmed on DATE (no entry for yesterday)` | der Sammler lief nicht oder scheiterte seit DATE | sehen Sie in `/var/log/argus.log` nach, führen Sie den Sammler von Hand aus |
| `never collected` | keine Lebenszeichen-Datei, obwohl die Quelle lesbar ist | führen Sie den Sammler von Hand aus, prüfen Sie `/etc/cron.d/argus` |

Zeilen, die eine Aktion erfordern, werden unter `TO CHECK` auf der Fehlerausgabe wiederholt.

## Einen Sammler von Hand ausführen

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/argus-doctor.sh
tail -n 20 /var/log/argus.log
```


## Häufige Ursachen

- **Kein Bild nach der ersten Nacht.** Prüfen Sie, ob `/etc/cron.d/argus` existiert und Cron läuft (`systemctl status cron`). Führen Sie `sudo /opt/argus/chart-daily.sh` aus und lesen Sie seine Meldung.
- **`chart-daily.sh: no data file for 2026 in /srv/argus/2026 — nothing to plot.`** Kein Sammler hat in diesem Jahr eine Datei geschrieben. Ein Server ohne jeden Angriff schreibt keine. Führen Sie `sudo /opt/argus/collect-ssh.sh` aus, um gestern zu sammeln.
- **SSH zeigt jeden Tag 0 Ereignisse.** `auth.log` fehlt und `journald` enthält die Protokolle unter einem anderen Unit-Namen. Setzen Sie `ARGUS_SSHD_UNIT="sshd"` in `/etc/argus/argus.conf` (der Standard ist `ssh`).
- **Weniger SSH-Angriffe als Fail2Ban-Sperren.** Argus zählt eine IP erst nach `ARGUS_SSH_THRESHOLD` fehlgeschlagenen Versuchen an einem Tag (standardmäßig 5), und Fail2Ban kann früher sperren. Senken Sie den Schwellenwert zum Vergleichen.
- **`argus-chart: unknown view`.** Die Ansichten sind `period`, `hourly` und `daily`.
- **`unknown series`.** Listen Sie die Namen mit `argus-chart period --list-series` auf.
- **`argus-fetch` meldet einen Host.** Der Server antwortete beim ersten Versuch nicht, und `argus-fetch` versucht nicht erneut. Prüfen Sie Alias, Schlüssel und Firewall, und führen Sie es dann erneut aus. Siehe [desk.md](desk.md).
- **Zugriff verweigert beim Schreiben eines Bildes.** `/srv/argus` gehört root: Verwenden Sie `sudo` oder `--out DIR` in Ihrem Home-Verzeichnis.
