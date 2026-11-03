# Install Argus on the server

The package goes on the **server**, the machine whose logs Argus reads. You do not install it on your desk: the desk only copies the charts (see [desk.md](desk.md)).

## What you get

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

`/srv/argus/` holds only counts, never an IP address, so it is readable by every user: you copy the charts without `sudo`.

## Requirements

A Debian or Ubuntu server with cron. The package depends on `gawk` and `gnuplot-nox`; `apt` installs them. `rsync` and `openssh-client` are recommended (they serve `argus-fetch`). Fail2Ban, CrowdSec and `jq` are optional. A server with 1 GB of RAM is enough: nothing stays running.

## Install

Download `argus_1.0.0-14_all.deb` from the releases page of the repository, then, on the server:

```bash
sudo apt install ./argus_1.0.0-14_all.deb
```

The cron jobs start that night: collection at 00:05, charts at 00:15, health check at 00:20. The first chart appears in `/srv/argus/2026/images/` after the first night.

## Try it now

To skip the first night, run the steps by hand on a server that already has log history:

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/chart-daily.sh
ls /srv/argus/2026/images/
```

Then draw a view:

```bash
sudo argus-chart period --month 2026-10
```

## Change a setting

`/etc/argus/argus.conf` is a shell file read by every script. Uncomment and edit only what you need:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=10         # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_IMG_WIDTH=3840           # image size in pixels
ARGUS_IMG_HEIGHT=2160
ARGUS_COULEUR_ssh_direct=orange   # colour of one series, any gnuplot colour name
```

Variable names use capitals and underscores, never hyphens. The series `caddy-xmlrpc` is therefore coloured by `ARGUS_COULEUR_caddy_xmlrpc`. All variables are listed in `man argus`.

## Remove

```bash
sudo apt remove argus     # removes the scripts, keeps /srv/argus and /etc/argus
sudo apt purge argus      # also removes /srv/argus and /etc/argus
```

Purge deletes your history. Copy it first with `argus-fetch` (see [desk.md](desk.md)).
