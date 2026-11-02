---
title: ARGUS-FETCH
section: 1
header: Argus
---

# NAME

argus-fetch - kopiert die Argus-Diagramme Ihrer Server auf diesen Computer

# ÜBERSICHT

**argus-fetch** [**--config** *DATEI*] [**--dest** *VERZEICHNIS*] [**--only** *ALIAS*]

**argus-fetch** {**-h**|**--help**}

# BESCHREIBUNG

Argus läuft auf den Servern und zeichnet die Diagramme dort. **argus-fetch** läuft auf Ihrem Arbeitsplatzrechner und kopiert die PNG-Bilder jedes Servers auf diesen Computer.

Für jeden Server der Konfigurationsdatei öffnet **argus-fetch** **eine** ssh-Verbindung, ohne Passwortabfrage und mit einem Verbindungs-Timeout von 10 Sekunden, kopiert die PNG-Dateien aus `<remote_path>/<year>/images/` und schließt sie. Es versucht nie erneut: Viele Server sperren eine Adresse nach einigen fehlgeschlagenen Anmeldungen. Ein Server, der nicht antwortet, wird auf der Standardfehlerausgabe gemeldet, die anderen Server werden trotzdem kopiert, und der Exit-Status ist 1. Eine lokal bereits vorhandene Datei wird nie überschrieben, und nichts wird gelöscht.

# OPTIONEN

**--config** *DATEI*
:   *DATEI* statt *~/.config/argus/hosts.conf* lesen.

**--dest** *VERZEICHNIS*
:   In *VERZEICHNIS* statt *~/argus-backup* kopieren.

**--only** *ALIAS*
:   Nur den Server dieses ssh-Alias behandeln.

**--local-source**
:   Testmodus. Der entfernte Pfad ist ein Verzeichnis dieses Computers, es wird keine ssh-Verbindung hergestellt, und der Alias benennt nur das Zielunterverzeichnis.

**-h**, **--help**
:   Gibt die Verwendung aus und beendet.

# DATEIEN

*~/.config/argus/hosts.conf*
:   Ein Server pro Zeile, `<ssh_alias>,<remote_path>`. Der Alias ist ein **Host**-Name aus *~/.ssh/config* oder eine **user@host**-Adresse; der Pfad ist **ARGUS_DATA_DIR** auf dem Server, standardmäßig */srv/argus/*. Leere Zeilen und Zeilen, die mit **#** beginnen, werden ignoriert.

`~/argus-backup/<ssh_alias>/<year>/images/`
:   Die kopierten Diagramme.

# RÜCKGABEWERTE

**0**
:   Jeder Server wurde kopiert.

**1**
:   Mindestens ein Server ist fehlgeschlagen, oder die Konfigurationsdatei fehlt.

**2**
:   Eine falsche Verwendung, oder **rsync** oder **ssh** fehlt.

# BEISPIELE

Deklarieren Sie einen Server und kopieren Sie dann:

```sh
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


Kopieren Sie einen Server in einen anderen Ordner:

```sh
argus-fetch --only server.example.org --dest ~/Documents/argus
```


# SIEHE AUCH

**argus**(7), **argus-chart**(1)
