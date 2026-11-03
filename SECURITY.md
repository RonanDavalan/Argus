# Security policy

## Supported versions

Only the latest published version of Argus receives security fixes. Today that is 1.0.0.

## Reporting a vulnerability

Report it privately through GitHub: open the **Security** tab of the repository, then **Report a vulnerability**. Please do not open a public issue for a vulnerability, because a public report exposes the servers that already run Argus before a fix exists.

You will get a first answer within 7 days. A confirmed vulnerability is fixed in a new package revision, and the report is credited in the changelog unless you ask otherwise.

A report made in good faith, following this policy, will not lead to any legal action from the maintainer.

## What is in scope

- the scripts installed under `/opt/argus/` and the commands `argus-chart` and `argus-fetch`;
- the files the package writes: `/etc/argus/`, `/etc/cron.d/argus` and `/srv/argus/`;
- the Debian package itself.

Argus reads authentication logs as root and writes only counts, never an IP address. A flaw that makes it write or send an address is in scope.

## What is not in scope

A fork or a repackaged version, a version that is not the latest, and the security of Fail2Ban, CrowdSec or SSH themselves.
