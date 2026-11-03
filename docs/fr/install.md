# Installer Argus sur le serveur

Le paquet va sur le **serveur**, la machine dont Argus lit les journaux. Vous ne l'installez pas sur votre poste de bureau : le poste de bureau ne fait que copier les graphiques (voir [desk.md](desk.md)).

## Ce que vous obtenez

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


`/srv/argus/` ne contient que des comptes, jamais une adresse IP, il est donc lisible par tous les utilisateurs : vous copiez les graphiques sans `sudo`.

## Prérequis

Un serveur Debian ou Ubuntu avec cron. Le paquet dépend de `gawk` et de `gnuplot-nox` ; `apt` les installe. `rsync` et `openssh-client` sont recommandés (ils servent à `argus-fetch`). Fail2Ban, CrowdSec et `jq` sont optionnels. Un serveur de 1 Go de RAM suffit : rien ne reste en cours d'exécution.

## Installation

Téléchargez `argus_1.0.0-13_all.deb` depuis la page des versions du dépôt, puis, sur le serveur :

```bash
sudo apt install ./argus_1.0.0-13_all.deb
```


Les tâches cron démarrent cette nuit-là : collecte à 00:05, graphiques à 00:15, contrôle de santé à 00:20. Le premier graphique apparaît dans `/srv/argus/2026/images/` après la première nuit.

## Essayer tout de suite

Pour sauter la première nuit, exécutez les étapes à la main sur un serveur qui possède déjà un historique de journaux :

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/chart-daily.sh
ls /srv/argus/2026/images/
```


Dessinez ensuite une vue :

```bash
sudo argus-chart period --month 2026-10
```


## Changer un réglage

`/etc/argus/argus.conf` est un fichier shell lu par chaque script. Décommentez et modifiez seulement ce dont vous avez besoin :

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=10         # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_IMG_WIDTH=3840           # image size in pixels
ARGUS_IMG_HEIGHT=2160
ARGUS_COULEUR_ssh_direct=orange   # colour of one series, any gnuplot colour name
```


Les noms de variables utilisent des majuscules et des traits de soulignement, jamais des traits d'union. La série `caddy-xmlrpc` est donc colorée par `ARGUS_COULEUR_caddy_xmlrpc`. Toutes les variables sont listées dans `man argus`.

## Désinstallation

```bash
sudo apt remove argus     # removes the scripts, keeps /srv/argus and /etc/argus
sudo apt purge argus      # also removes /srv/argus and /etc/argus
```


La purge supprime aussi votre historique. Copiez-le d'abord avec `argus-fetch` (voir [desk.md](desk.md)).
