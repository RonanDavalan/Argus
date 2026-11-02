# Troubleshooting

A chart with no attack can mean a quiet day or a collector that stopped. The data files cannot tell them apart, because a day without attack writes no line. `argus-doctor.sh` can: every collector writes one line a day in `/srv/argus/<year>/.heartbeat/<source>.txt`, `<date> <number of events>`, even when the number is 0.

## Run the check

```bash
sudo /opt/argus/argus-doctor.sh
```

The cron job runs it every night at 00:20 and appends the output to `/var/log/argus.log`. The exit code is 0 when there is nothing to report, 1 otherwise. A healthy server prints:

```
== Source availability ==

== Heartbeats (2026) ==
  ssh : ok
    -> up to date, yesterday: 12 event(s)
  fail2ban : absent
  crowdsec : absent

Nothing to report.
```

## What each line means

`<source> : ok` or `absent` says whether the source can be read now: `auth.log` or `journald` for `ssh`, `fail2ban-client` and its log for `fail2ban`, `cscli` and `jq` for `crowdsec`. `absent` for Fail2Ban or CrowdSec is normal when you do not run them.

| Line under the source | Meaning | What to do |
|---|---|---|
| `up to date, yesterday: N event(s)` | collected yesterday, N events (0 is a quiet day) | nothing |
| `last confirmed on DATE (no entry for yesterday)` | the collector did not run or failed since DATE | look at `/var/log/argus.log`, run the collector by hand |
| `never collected` | no heartbeat file, though the source is readable | run the collector by hand, check `/etc/cron.d/argus` |

Lines that need action are repeated under `TO CHECK` on the error output.

## Run a collector by hand

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/argus-doctor.sh
tail -n 20 /var/log/argus.log
```

## Common causes

- **No image after the first night.** Check that `/etc/cron.d/argus` exists and that cron runs (`systemctl status cron`). Run `sudo /opt/argus/chart-daily.sh` and read its message.
- **`no data file for 2026 … nothing to plot`.** No collector has written a file this year. Run `sudo /opt/argus/collect-ssh.sh`; a quiet server writes no file until its first attack.
- **SSH shows 0 events every day.** `auth.log` is absent and `journald` holds the logs under another unit name. Set `ARGUS_SSHD_UNIT="sshd"` in `/etc/argus/argus.conf` (the default is `ssh`).
- **Fewer attacks than Fail2Ban bans.** `ARGUS_SSH_THRESHOLD` (5 failed attempts in one day by default) is stricter than your Fail2Ban `maxretry`. Lower it to compare.
- **`argus-chart: unknown view`.** The views are `period`, `hourly` and `daily`.
- **`unknown series`.** List the names with `argus-chart period --list-series`.
- **`argus-fetch` reports a host.** The server did not answer on the first try, and `argus-fetch` does not retry. Check the alias, the key and the firewall, then run it again. See [desk.md](desk.md).
- **Permission denied writing an image.** `/srv/argus` belongs to root: use `sudo`, or `--out DIR` in your home.
