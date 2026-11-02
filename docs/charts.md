# Charts: windows, split, hour, series

`argus-chart` has three views. Run it on the server, as root to write in `/srv/argus/<year>/images/`, or as an ordinary user with `--out DIR`.

```
argus-chart daily  [YEAR]               one point per day, the whole year
argus-chart period [window] [options]   one line per series over a window
argus-chart hourly [window] [options]   24 positions, 00 to 23, per series
```

Each file is named `<today>_argus_<view>_<window>.png`, for example `2026-11-02_argus_period_week-2026-W44.png`.

## Windows

`period` and `hourly` take the same windows. Without one, they use the current year.

| Option | Window | Example |
|---|---|---|
| `--day YYYY-MM-DD` | one day | `--day 2026-10-30` |
| `--week YYYY-Www` | ISO week, Monday to Sunday | `--week 2026-W44` |
| `--month YYYY-MM` | calendar month | `--month 2026-10` |
| `--quarter YYYY-Qn` | quarter, `n` from 1 to 4 | `--quarter 2026-Q4` |
| `--year YYYY` | calendar year | `--year 2025` |
| `--from D --to D` | range, both days included | `--from 2025-12-01 --to 2026-01-31` |

Weeks follow ISO 8601: week 1 of 2027 starts on Monday 2027-01-04, and 2026 has a week 53. A window that spans two years reads the data of both.

```bash
argus-chart period --day 2026-10-30 --out ~/argus-out
argus-chart period --from 2025-12-01 --to 2026-01-31 --out ~/argus-out
```

## Split a long window

`--split` draws one chart per sub-period instead of one long chart:

```bash
argus-chart period --month 2026-10 --split week --out ~/argus-out
argus-chart period --year 2026 --split month --out ~/argus-out
```

`--split week` suits a month or a quarter, `--split month` a quarter or a year. The first command writes one file per ISO week touching October, each cut to the window, named `…_month-2026-10_week-2026-W41.png`.

## The hour of the day

`hourly` adds up, for each series, the attacks seen at each hour over the window, and draws 24 positions. It shows when you are attacked, not when over the year.

```bash
argus-chart hourly --week 2026-W44 --out ~/argus-out
```

The hour is the **local time of the server**, as written by the collectors. It is the hour at which the attack was seen in the logs, not the hour it began. The title says "local server time". A change of daylight saving time adds or removes one hour on one day; over a week or more the effect does not show.

## Series

A series is one line: `ssh_direct` for SSH, `ip_ban_<jail>` for each Fail2Ban jail, `ip_ban_<scenario>` for each CrowdSec scenario. The name is the data file name without the year, so `ssh_direct_2026.txt` is the series `ssh_direct`.

Series are overlaid, never added up: Argus does not invent one score from different tools. Each series keeps the same colour from year to year (set it with `ARGUS_COULEUR_<series>`, otherwise it comes from a hash of the name).

```bash
argus-chart period --week 2026-W44 --list-series
argus-chart period --week 2026-W44 --series ssh_direct
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd --out ~/argus-out
```

An unknown name in `--series` stops the command with the exit code 2 and lists the available names.

## Read the numbers instead of the picture

`--print-data` prints the table behind the chart on standard output (tab-separated, header starting with `#`) and draws nothing:

```bash
argus-chart period --week 2026-W44 --print-data
argus-chart hourly --day 2026-10-30 --print-data
```

## Slices at hour 00 (`T00`)

A data line is `<count> <date>T<hour>`, for example `492 2026-10-30T14`. Files from before the collectors were hourly hold one line per day, all written as `T00`. A series made only of `T00` slices has no hour information, so `hourly` leaves it out instead of drawing one bar at midnight. It prints the message `series 'legacy' excluded: all its slices are at hour 00 (daily data, no hourly depth)` on the error output and writes `excluded series: no hourly data: legacy` in the title of the chart. `period` and `daily` still draw it, as daily points.

## Chart language

`ARGUS_LANG` sets the titles and the axes: `en` (default), `fr`, `de` or `es`.

```bash
ARGUS_LANG=de argus-chart period --week 2026-W44 --out ~/argus-out
```
