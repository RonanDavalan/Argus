---
title: ARGUS
section: 7
header: Argus
---

# NAME

argus - count the attacks against a server and keep their history as charts

# DESCRIPTION

No permanent service, no database, suited to machines with less than 1 GB of RAM.

Argus counts the SSH attacks of a server and, when they are installed, the bans of Fail2Ban and CrowdSec. A nightly cron job writes plain text files and draws charts. Nothing runs between two nights.
Argus never stores or shows an attacker's IP address, only counts per hour and per day. An attack is a source IP that reaches **ARGUS_SSH_THRESHOLD** failed authentication attempts within one day.

Grafana is a continuous view of an infrastructure: a service that runs all the time and can be queried live. Argus is a periodic snapshot of the security history: one image per night, read when you want.

# TWO STEPS

The package is installed on the **server**, the machine that is attacked, not on the desk (the computer you read from).

1. On the server, the package counts the attacks and draws the charts every night.
2. On the desk, **argus-fetch**(1) copies the images from the servers to the computer you read them on.

**argus-chart**(1) draws other views of the same data, on the server.

# FILES

*/opt/argus/*
:   The scripts: *collect-ssh.sh*, *collect-fail2ban.sh*, *collect-crowdsec.sh*, *chart-daily.sh*, *chart-period.sh*, *chart-hourly.sh*, *argus-lib.sh*, *argus-doctor.sh*.

*/etc/argus/argus.conf*
:   Optional settings, a shell file read by every script. Every line is commented out.

*/etc/cron.d/argus*
:   Collection at 00:05, charts at 00:15, health check at 00:20.

`/srv/argus/<year>/<series>_<year>.txt`
:   One line per hour with an attack, **\<count\> \<YYYY-MM-DD\>T\<HH\>**. A series is the file name without the year: *ssh_direct*, *ip_ban_\<jail\>*.

`/srv/argus/<year>/.heartbeat/`
:   One line a day per collector, read by *argus-doctor.sh*.

`/srv/argus/<year>/images/`
:   The PNG charts.

*/var/log/argus.log*
:   Output of the cron jobs.

# ENVIRONMENT

The variables are set in */etc/argus/argus.conf*. A variable already set in the environment wins over the file.

**ARGUS_DATA_DIR**
:   Data and images. Default */srv/argus*.

**ARGUS_SSH_THRESHOLD**
:   Failed attempts of one IP in one day that make an attack. Default 5.

**ARGUS_AUTHLOG**
:   SSH log. Default */var/log/auth.log*; when it does not exist, the journal is read.

**ARGUS_SSHD_UNIT**
:   systemd unit read from the journal. Default *ssh*.

**ARGUS_FAIL2BAN_LOG**
:   Fail2Ban log. Default */var/log/fail2ban.log*.

**ARGUS_DATA_OWNER**
:   User that owns the files after each write.

**ARGUS_LANG**
:   Language of the charts: *en* (default), *fr*, *de* or *es*.

**ARGUS_IMG_WIDTH**, **ARGUS_IMG_HEIGHT**
:   Image size in pixels. Default 3840 and 2160.

**ARGUS_COULEUR_**`<series>`
:   Colour of a series, any gnuplot colour name. In the name of the variable, hyphens of the series become underscores.

**ARGUS_CONF**
:   Path of the configuration file instead of */etc/argus/argus.conf*.

# EXAMPLES

Check that every collector ran yesterday:

```sh
sudo /opt/argus/argus-doctor.sh
```

Draw the count of the fourth quarter of 2026 as one chart:

```sh
sudo argus-chart period --quarter 2026-Q4
```

# SEE ALSO

**argus-chart**(1), **argus-fetch**(1)
