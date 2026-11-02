---
title: ARGUS
section: 7
header: Argus
---

# NOM

argus - compte les attaques contre un serveur et conserve leur historique sous forme de graphiques

# DESCRIPTION

Pas de service permanent, pas de base de données, adapté aux machines de moins de 1 Go de RAM.

Argus compte les attaques SSH d'un serveur et, lorsqu'ils sont installés, les bannissements de Fail2Ban et de CrowdSec. Une tâche cron s'exécute chaque nuit, écrit des fichiers texte plats et dessine des graphiques. Rien ne tourne entre deux nuits.
Argus ne stocke ni n'affiche jamais l'adresse IP d'un attaquant, seulement des comptes par heure et par jour. Une attaque est une IP source qui atteint **ARGUS_SSH_THRESHOLD** tentatives d'authentification échouées en une journée.

Grafana est une vue continue d'une infrastructure : un service qui tourne en permanence et peut être interrogé en direct. Argus est un instantané périodique de l'historique de sécurité : une image par nuit, lue quand vous le souhaitez.

# DEUX TEMPS

Le paquet s'installe sur le **serveur**, la machine attaquée, et non sur le poste de bureau (l'ordinateur depuis lequel vous lisez).

1. Sur le serveur, le paquet compte les attaques et dessine les graphiques chaque nuit.
2. Sur le poste de bureau, **argus-fetch**(1) copie les images depuis les serveurs vers l'ordinateur sur lequel vous les lisez.

**argus-chart**(1) dessine d'autres vues des mêmes données, sur le serveur.

# FICHIERS

*/opt/argus/*
:   Les scripts : *collect-ssh.sh*, *collect-fail2ban.sh*, *collect-crowdsec.sh*, *chart-daily.sh*, *chart-period.sh*, *chart-hourly.sh*, *argus-lib.sh*, *argus-doctor.sh*.

*/etc/argus/argus.conf*
:   Réglages facultatifs, un fichier shell lu par chaque script. Chaque ligne est commentée.

*/etc/cron.d/argus*
:   Collecte à 00:05, graphiques à 00:15, contrôle de santé à 00:20.

`/srv/argus/<year>/<series>_<year>.txt`
:   Une ligne par heure avec une attaque, **\<count\> \<YYYY-MM-DD\>T\<HH\>**. Une série est le nom du fichier sans l'année : *ssh_direct*, *ip_ban_\<jail\>*.

`/srv/argus/<year>/.heartbeat/`
:   Une ligne par jour et par collecteur, lue par *argus-doctor.sh*.

`/srv/argus/<year>/images/`
:   Les graphiques PNG.

*/var/log/argus.log*
:   Sortie des tâches cron.

# ENVIRONNEMENT

Les variables sont définies dans */etc/argus/argus.conf*. Une variable déjà définie dans l'environnement a la priorité sur le fichier.

**ARGUS_DATA_DIR**
:   Données et images. Par défaut */srv/argus*.

**ARGUS_SSH_THRESHOLD**
:   Tentatives échouées d'une IP en une journée qui constituent une attaque. Par défaut 5.

**ARGUS_AUTHLOG**
:   Journal SSH. Par défaut */var/log/auth.log* ; lorsqu'il n'existe pas, le journal systemd est lu.

**ARGUS_SSHD_UNIT**
:   Unité systemd lue dans le journal. Par défaut *ssh*.

**ARGUS_FAIL2BAN_LOG**
:   Journal Fail2Ban. Par défaut */var/log/fail2ban.log*.

**ARGUS_DATA_OWNER**
:   Utilisateur propriétaire des fichiers après chaque écriture.

**ARGUS_LANG**
:   Langue des graphiques : *en* (par défaut), *fr*, *de* ou *es*.

**ARGUS_IMG_WIDTH**, **ARGUS_IMG_HEIGHT**
:   Taille de l'image en pixels. Par défaut 3840 et 2160.

**ARGUS_COULEUR_**`<series>`
:   Couleur d'une série, tout nom de couleur gnuplot. Dans le nom de la variable, les traits d'union de la série deviennent des traits de soulignement.

**ARGUS_CONF**
:   Chemin du fichier de configuration au lieu de */etc/argus/argus.conf*.

# EXEMPLES

Vérifiez que chaque collecteur s'est exécuté la veille :

```sh
sudo /opt/argus/argus-doctor.sh
```


Dessinez le compte du quatrième trimestre 2026 en un seul graphique :

```sh
sudo argus-chart period --quarter 2026-Q4
```


# VOIR AUSSI

**argus-chart**(1), **argus-fetch**(1)
