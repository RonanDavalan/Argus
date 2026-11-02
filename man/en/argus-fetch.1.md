---
title: ARGUS-FETCH
section: 1
header: Argus
---

# NAME

argus-fetch - copy the Argus charts of your servers to this computer

# SYNOPSIS

**argus-fetch** [**--config** *FILE*] [**--dest** *DIR*] [**--only** *ALIAS*]

**argus-fetch** {**-h**|**--help**}

# DESCRIPTION

Argus runs on the servers and draws the charts there. **argus-fetch** runs on your desk and copies the PNG images of each server to this computer.

For each server of the configuration file, **argus-fetch** opens **one** ssh connection, with no password prompt and a connect timeout of 10 seconds, copies the PNG files of `<remote_path>/<year>/images/` and closes. It never retries: many servers ban an address after a few failed logins. A server that does not answer is reported on standard error, the other servers are still copied, and the exit status is 1. A file already present locally is never overwritten, and nothing is deleted.

# OPTIONS

**--config** *FILE*
:   Read *FILE* instead of *~/.config/argus/hosts.conf*.

**--dest** *DIR*
:   Copy into *DIR* instead of *~/argus-backup*.

**--only** *ALIAS*
:   Handle only the server of that ssh alias.

**--local-source**
:   Test mode. The remote path is a directory of this computer, no ssh connection is made, and the alias only names the destination sub-directory.

**-h**, **--help**
:   Print the usage and exit.

# FILES

*~/.config/argus/hosts.conf*
:   One server per line, `<ssh_alias>,<remote_path>`. The alias is a **Host** name of *~/.ssh/config* or a **user@host** address; the path is **ARGUS_DATA_DIR** on the server, */srv/argus/* by default. Empty lines and lines starting with **#** are ignored.

`~/argus-backup/<ssh_alias>/<year>/images/`
:   The copied charts.

# EXIT STATUS

**0**
:   Every server was copied.

**1**
:   At least one server failed, or the configuration file is missing.

**2**
:   A wrong usage, or **rsync** or **ssh** is missing.

# EXAMPLES

Declare a server, then copy:

```sh
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```

Copy one server into another folder:

```sh
argus-fetch --only server.example.org --dest ~/Documents/argus
```

# SEE ALSO

**argus**(7), **argus-chart**(1)
