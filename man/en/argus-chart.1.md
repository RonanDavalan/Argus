---
title: ARGUS-CHART
section: 1
header: Argus
---

# NAME

argus-chart - draw the Argus charts of a server

# SYNOPSIS

**argus-chart period** [*window*] [*options*]

**argus-chart hourly** [*window*] [*options*]

**argus-chart daily** [*year*]

**argus-chart** {**-h**|**--help**}

# DESCRIPTION

**argus-chart** is the single entry point of the charts. It passes the options after the view name, unchanged, to the script of that view, looked up next to the command and then in */opt/argus*. Run it on the server, as root to write in */srv/argus*, or as an ordinary user with **--out**.

**period**
:   The count of each series over a window, one line per series. Script *chart-period.sh*.

**hourly**
:   The count of each series at each hour of the day, 00 to 23, added up over a window. The hour is the local time of the server. Script *chart-hourly.sh*.

**daily**
:   The history of one year, one point per day, the current year by default. Script *chart-daily.sh*.

Series are overlaid, never added up.

# WINDOW

One of the following, for **period** and **hourly**. Without one, the window is the current year. A window that spans two years reads the data of both.

**--day** *YYYY-MM-DD*
:   One day.

**--week** *YYYY-Www*
:   An ISO 8601 week, Monday to Sunday.

**--month** *YYYY-MM*
:   A calendar month.

**--quarter** *YYYY-Qn*
:   A quarter, *n* from 1 to 4.

**--year** *YYYY*
:   A calendar year.

**--from** *YYYY-MM-DD* **--to** *YYYY-MM-DD*
:   A range, both days included.

# OPTIONS

**--series** *a,b*
:   Only these series, named without the year suffix. An unknown name stops the command with the exit status 2.

**--list-series**
:   Print the series of the window and exit. With **hourly**, only the series that are plotted.

**--split** *week*|*month*
:   **period** only. One chart per ISO week, or per calendar month, of the window. Sub-periods are cut to the window.

**--out** *DIR*
:   Output directory. Default `/srv/argus/<year>/images`.

**--print-data**
:   Print the table behind the chart on standard output, tab-separated, header line starting with **#**, and exit. Nothing is drawn.

**-h**, **--help**
:   Print the usage and exit. After a view name, print the options of that view.

# FILES

`<out>/<YYYY-MM-DD>_argus_<view>_<window>.png`
:   The chart. The date is today; the window is for example *week-2026-W44*, *month-2026-10* or *range-2025-12-01_2026-01-31*. With **--split**, it is `<parent>_<sub-period>`, for example *month-2026-10_week-2026-W41*.

# EXIT STATUS

**0**
:   Done.

**2**
:   A wrong usage, an unknown series, or a view that this version does not have.

Any other status is the one of the script that was run.

# EXAMPLES

One week, then the same week by hour:

```sh
argus-chart period --week 2026-W44 --out ~/argus-out
argus-chart hourly --week 2026-W44 --out ~/argus-out
```

One chart per week of a month, for SSH only:

```sh
argus-chart period --month 2026-10 --split week --series ssh_direct --out ~/argus-out
```

# SEE ALSO

**argus**(7), **argus-fetch**(1)
