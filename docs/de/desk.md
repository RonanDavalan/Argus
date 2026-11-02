# Die Diagramme auf den Arbeitsplatzrechner holen und lesen

Argus läuft auf Ihren Servern und zeichnet die Diagramme dort. `argus-fetch` kopiert die Bilder auf den Computer, an dem Sie arbeiten. Vom Server wird nichts gesendet: Sie holen die Bilder, wann Sie wollen.

## Was Sie erhalten

```
~/.config/argus/hosts.conf              the servers to copy, one per line
~/argus-backup/
└── server.example.org/                 one folder per ssh alias
    └── 2026/
        └── images/
            ├── 2026-11-02_argus_4k.png
            └── 2026-11-02_argus_period_week-2026-W44.png
```


## Voraussetzungen

`bash`, `ssh` und `rsync` auf dem Arbeitsplatzrechner. Das Paket installiert `argus-fetch` in `/usr/bin`; auf einem anderen System kopieren Sie die eine Datei `argus-fetch` aus dem Repository in einen Ordner Ihres `PATH`. Ihr `ssh` muss sich bereits mit einem Schlüssel beim Server anmelden, ohne Passwortabfrage: `argus-fetch` fragt nie danach.

## Die Server deklarieren

Ein Server pro Zeile, `<ssh alias>,<data directory>`. Der Alias ist ein `Host`-Name aus `~/.ssh/config` (oder `user@host`); das Verzeichnis ist `ARGUS_DATA_DIR` auf diesem Server, standardmäßig `/srv/argus/`.

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\nbackup.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
cat ~/.config/argus/hosts.conf
```


Leere Zeilen und Zeilen, die mit `#` beginnen, werden ignoriert. Das Repository liefert `hosts.conf.example`.

## Kopieren

```bash
argus-fetch
```


Für jeden Server öffnet es **eine** Verbindung, kopiert die PNG-Dateien aus `<directory>/<year>/images/` und schließt sie. Eine Datei, die bereits auf Ihrem Arbeitsplatzrechner liegt, wird nie überschrieben, und nichts wird gelöscht. Führen Sie es so oft aus, wie Sie wollen: Nur neue Bilder werden kopiert.

Um nur einen Server zu kopieren oder die Kopien anderswo abzulegen:

```bash
argus-fetch --only server.example.org
argus-fetch --dest ~/Documents/argus
```


## Eine Verbindung, kein erneuter Versuch

Wenn ein Server nicht antwortet, meldet `argus-fetch` dies einmal auf der Fehlerausgabe, fährt mit den anderen Servern fort und endet mit dem Exit-Code 1. Es versucht nie erneut, weil viele Server eine Adresse nach einigen fehlgeschlagenen Anmeldungen sperren. Finden Sie die Ursache (Schlüssel, Alias, Firewall, ausgeschalteter Server), und führen Sie den Befehl dann selbst erneut aus.

## Die Diagramme lesen

Öffnen Sie die Bilder mit einem beliebigen Betrachter:

```bash
xdg-open ~/argus-backup/server.example.org/2026/images/
```


Ein Diagramm zeigt eine Linie pro Serie. Bei einem Zeitfenster von höchstens 31 Punkten wird die genaue Anzahl an jedem Punkt geschrieben. Eine Ansicht, die es noch nicht gibt (eine andere Woche, ein Monat pro Stunde), wird auf dem Server gezeichnet, als root, damit das Bild im Bilderordner landet:

```bash
ssh server.example.org
sudo argus-chart period --week 2026-W44
```


Das nächste `argus-fetch` kopiert das neue Bild mit den anderen. Siehe [charts.md](charts.md) für die Zeitfenster, die Sie anfordern können.
