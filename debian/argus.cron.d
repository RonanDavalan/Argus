# /etc/cron.d/argus — installed by the argus package.
# Local overrides belong in /etc/argus/argus.conf, not here (this file does
# not survive a purge, and edits here are overwritten on package upgrade).
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

5  0 * * * root /opt/argus/collect-ssh.sh >> /var/log/argus.log 2>&1
5  0 * * * root /opt/argus/collect-fail2ban.sh >> /var/log/argus.log 2>&1
5  0 * * * root /opt/argus/collect-crowdsec.sh >> /var/log/argus.log 2>&1
15 0 * * * root /opt/argus/chart-daily.sh >> /var/log/argus.log 2>&1
