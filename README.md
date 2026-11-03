# Argus

<p align="center">
  <a href="https://github.com/RonanDavalan/Argus/releases/latest"><img src="https://img.shields.io/github/v/release/RonanDavalan/Argus?label=version" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Debian_%C2%B7_Ubuntu-informational.svg" alt="Debian and Ubuntu">
  <img src="https://img.shields.io/badge/Shell-Bash_%C2%B7_gnuplot-lightgrey.svg" alt="Bash and gnuplot">
</p>

**English** | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

<p align="center">
  <a href="https://argus.davalan.fr/images/argus-daily-4k.png"><img src="https://argus.davalan.fr/images/argus-daily-1600.jpg" alt="Argus: daily chart of attacks per series, one line each for SSH, Fail2Ban and CrowdSec" width="800"></a>
</p>

No permanent service, no database, suited to machines with less than 1 GB of RAM.

Argus counts the attacks against your servers, SSH by itself and, when they are installed, the bans of Fail2Ban and CrowdSec, and keeps the history as charts. A nightly cron job writes plain text files and draws the charts. Nothing runs between two nights.

Argus never stores or shows an attacker's IP address, only counts per hour and per day. An **attack** is a source IP that reaches a minimum number of failed authentication attempts within one day (5 by default), so one mistyped password does not count.

Grafana is a continuous view of an infrastructure: a service that runs all the time and can be queried live. Argus is a periodic snapshot of your security history: one image per night, read when you want. Grafana can aggregate by week or by year too, at the price of a permanent service, a time-series database and a dashboard to build; Argus has none of the three, which is why it fits a 1 GB server.

## Install in two steps

If you usually install a program on the computer you work on, here it is the reverse. The package goes on the **server**, the machine that is attacked. Your own computer, the desk, installs nothing of the package and only receives the images.

1. **On the server** (the machine that is attacked), install the package. It counts the attacks and draws the charts every night. There is nothing to launch afterwards.
2. **On your desk** (the computer you read from), run `argus-fetch`. It copies the chart images from your servers to your computer.

Where each part lives:

```
server.example.org (the server)           your desk
─────────────────────────────────         ──────────────────────────────
/opt/argus/        scripts                ~/.config/argus/hosts.conf
/etc/argus/        argus.conf                 the list of your servers
/srv/argus/<year>/ data and images        ~/argus-backup/<server>/<year>/images/
/usr/bin/argus-chart                          the copied charts
/usr/bin/argus-fetch   ── copies images ──►
```

Step 1, on the server (Debian or Ubuntu):

```bash
sudo apt install ./argus_1.0.0-14_all.deb
```

Step 2, on your desk. Put your servers in the file `~/.config/argus/hosts.conf`, one per line, as `<ssh alias>,<data directory>`, then run `argus-fetch`:

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```

`argus-fetch` is installed by the same package. On a desk that is not a Debian machine, copy the single script `argus-fetch` from this repository; it needs only `bash`, `ssh` and `rsync`. Details: [docs/install.md](docs/install.md) and [docs/desk.md](docs/desk.md).

## The three views

`argus-chart` draws a chart for the window you choose. Run it on the server. Each command writes a PNG in `/srv/argus/<year>/images/` (add `--out DIR` to write elsewhere, which an ordinary user needs).

- `argus-chart daily` is the history of the year, one point per day.
- `argus-chart period` is the count of each series over a window.
- `argus-chart hourly` is the count per hour of the day over a window, from 00 to 23.

Ten windows to copy:

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

Series are drawn side by side, never added up: SSH, each Fail2Ban jail and each CrowdSec scenario keep their own line and colour. Details: [docs/charts.md](docs/charts.md).

## One connection per host, no retry

`argus-fetch` opens **one connection per host** and **never retries**. Many servers ban an address after a few failed logins, so a second attempt could lock you out. A host that does not answer is reported once, the other hosts are still copied, and the exit code is 1. Fix the cause (key, alias, firewall, machine off), then run it again by hand.

## Configuration

Everything works with the defaults. To change one, edit `/etc/argus/argus.conf` on the server; the file is read by every script and ships with each value commented out:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=5          # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_DATA_DIR="/srv/argus"    # where the data and the images are written
```

The other variables (log paths, image size, series colours) are listed in `man argus`.

## Check that it works

```bash
sudo /opt/argus/argus-doctor.sh
```

It tells whether each source (SSH, Fail2Ban, CrowdSec) was collected yesterday. See [docs/troubleshooting.md](docs/troubleshooting.md).

## Documentation

- [docs/install.md](docs/install.md): install on the server, layout, uninstall
- [docs/desk.md](docs/desk.md): copy the charts to your desk and read them
- [docs/charts.md](docs/charts.md): windows, split, hour, series, time zone, `T00` slices
- [docs/troubleshooting.md](docs/troubleshooting.md): what `argus-doctor.sh` says and what to do
- Manual pages: `man argus`, `man argus-chart`, `man argus-fetch` (sources in `man/en/`)

---

## Credits

Argus is the result of a human-LLM collaboration, with the roles written down as they were actually played. The full list is in [CONTRIBUTORS.md](CONTRIBUTORS.md).

*   **Ronan Davalan** — Architect and arbiter: original scripts (2024), decisions, validation and testing.
*   **Claude Code (Anthropic)** — Lead developer: collectors, chart rendering, `argus-doctor.sh`, Debian package, documentation.
*   **Gemini (Google)** — Synthesizer and strategic co-writer: planning and framing of the project's purpose.
*   **Gemini (Google), GLM-5.3-Flash Free and Gemini 4 Argon** — Graphic designers: the project's visual identity (mark, icon, favicon), adopted by Ronan Davalan on 2026-11-02.
*   **DeepSeek** — Field companion: CrowdSec setup on a real server used to validate `collect-crowdsec.sh`.
*   **DeepSeek Flash** — Site content in English, then the French, German and Spanish translations of the documentation, manual pages and site.
*   **Muse Spark 1.3 Contributor** — Site styling: integration of the logo, the favicon and the chart image.
*   **gd2:** Ronan Davalan's late brother. He taught Ronan Git and how to use it, advised on this project, and made the first outside edit to its README (2024-08-07).

---

## License

MIT — see `LICENSE`.
