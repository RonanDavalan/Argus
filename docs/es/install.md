# Instalar Argus en el servidor

El paquete va en el **servidor**, la máquina cuyos registros lee Argus. No lo instale en su equipo de escritorio: el equipo de escritorio solo copia los gráficos (véase [desk.md](desk.md)).

## Lo que obtiene

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


`/srv/argus/` solo contiene recuentos, nunca una dirección IP, por lo que cualquier usuario puede leerlo: usted copia los gráficos sin `sudo`.

## Requisitos

Un servidor Debian o Ubuntu con cron. El paquete depende de `gawk` y `gnuplot-nox`; `apt` los instala. Se recomiendan `rsync` y `openssh-client` (sirven a `argus-fetch`). Fail2Ban, CrowdSec y `jq` son opcionales. Basta un servidor con 1 GB de RAM: nada queda en ejecución.

## Instalación

Descargue `argus_1.0.0-13_all.deb` de la página de versiones del repositorio y luego, en el servidor:

```bash
sudo apt install ./argus_1.0.0-13_all.deb
```


Las tareas cron empiezan esa noche: recogida a las 00:05, gráficos a las 00:15, comprobación de estado a las 00:20. El primer gráfico aparece en `/srv/argus/2026/images/` tras la primera noche.

## Probarlo ahora

Para saltarse la primera noche, ejecute los pasos a mano en un servidor que ya tenga historial de registros:

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/chart-daily.sh
ls /srv/argus/2026/images/
```


Luego dibuje una vista:

```bash
sudo argus-chart period --month 2026-10
```


## Cambiar un ajuste

`/etc/argus/argus.conf` es un archivo de shell que lee cada script. Descomente y modifique solo lo que necesite:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=10         # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_IMG_WIDTH=3840           # image size in pixels
ARGUS_IMG_HEIGHT=2160
ARGUS_COULEUR_ssh_direct=orange   # colour of one series, any gnuplot colour name
```


Los nombres de variables usan mayúsculas y guiones bajos, nunca guiones. Por eso la serie `caddy-xmlrpc` se colorea con `ARGUS_COULEUR_caddy_xmlrpc`. Todas las variables se enumeran en `man argus`.

## Desinstalación

```bash
sudo apt remove argus     # removes the scripts, keeps /srv/argus and /etc/argus
sudo apt purge argus      # also removes /srv/argus and /etc/argus
```


La purga también borra su historial. Cópielo primero con `argus-fetch` (véase [desk.md](desk.md)).
