# Copy the charts to your desk and read them

Argus runs on your servers and draws the charts there. `argus-fetch` copies the images to the computer you work on. Nothing is sent from the server: you pull when you want.

## What you get

```
~/.config/argus/hosts.conf              the servers to copy, one per line
~/argus-backup/
└── server.example.org/                 one folder per ssh alias
    └── 2026/
        └── images/
            ├── 2026-11-02_argus_4k.png
            └── 2026-11-02_argus_period_week-2026-W44.png
```

## Requirements

`bash`, `ssh` and `rsync` on the desk. The package installs `argus-fetch` in `/usr/bin`; on another system, copy the one file `argus-fetch` from the repository to a folder of your `PATH`. Your `ssh` must already log in to the server with a key, without a password prompt: `argus-fetch` never asks for one.

## Declare the servers

One server per line, `<ssh alias>,<data directory>`. The alias is a `Host` name of `~/.ssh/config` (or `user@host`); the directory is `ARGUS_DATA_DIR` on that server, `/srv/argus/` by default.

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\nbackup.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
cat ~/.config/argus/hosts.conf
```

Empty lines and lines starting with `#` are ignored. The repository ships `hosts.conf.example`.

## Copy

```bash
argus-fetch
```

For each server it opens **one** connection, copies the PNG files of `<directory>/<year>/images/`, and closes. A file already on your desk is never overwritten and nothing is deleted. Run it as often as you like: only new images are copied.

To copy one server only, or to put the copies elsewhere:

```bash
argus-fetch --only server.example.org
argus-fetch --dest ~/Documents/argus
```

## One connection, no retry

If a server does not answer, `argus-fetch` says so once on the error output, goes on with the other servers, and ends with the exit code 1. It never tries again, because many servers ban an address after a few failed logins. Find the cause (key, alias, firewall, server off), then run the command again yourself.

## Read the charts

Open the images with any viewer:

```bash
xdg-open ~/argus-backup/server.example.org/2026/images/
```

A chart shows one line per series, with the exact count at each point. A view that does not exist yet (another week, a month by hour) is drawn on the server, as root so that the image lands in the images folder:

```bash
ssh server.example.org
sudo argus-chart period --week 2026-W44
```

The next `argus-fetch` copies the new image with the others. See [charts.md](charts.md) for the windows you can ask for.
