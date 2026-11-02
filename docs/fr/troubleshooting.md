# Dépannage

Un graphique sans attaque peut signifier une journée calme ou un collecteur qui s'est arrêté. Les fichiers de données ne permettent pas de les distinguer, car un jour sans attaque n'écrit aucune ligne. `argus-doctor.sh` le peut : chaque collecteur écrit une ligne par jour dans `/srv/argus/<year>/.heartbeat/<source>.txt`, `<date> <number of events>`, même lorsque le nombre vaut 0.

## Lancer le contrôle

```bash
sudo /opt/argus/argus-doctor.sh
```


La tâche cron l'exécute chaque nuit à 00:20 et ajoute la sortie à `/var/log/argus.log`. Le code de sortie est 0 lorsqu'il n'y a rien à signaler, 1 sinon. Un serveur sain affiche :

```
== Source availability ==

== Heartbeats (2026) ==
  ssh : ok
    -> up to date, yesterday: 12 event(s)
  fail2ban : absent
  crowdsec : absent

Nothing to report.
```


## Ce que signifie chaque ligne

`<source> : ok` ou `absent` indique si la source peut être lue maintenant : `auth.log` ou `journald` pour `ssh`, `fail2ban-client` et son journal pour `fail2ban`, `cscli` et `jq` pour `crowdsec`. `absent` pour Fail2Ban ou CrowdSec est normal lorsque vous ne les exécutez pas.

| Ligne sous la source | Signification | Que faire |
|---|---|---|
| `up to date, yesterday: N event(s)` | collectée hier, N événements (0 est une journée calme) | rien |
| `last confirmed on DATE (no entry for yesterday)` | le collecteur ne s'est pas exécuté ou a échoué depuis DATE | regardez `/var/log/argus.log`, lancez le collecteur à la main |
| `never collected` | aucun fichier de battement de vie, bien que la source soit lisible | lancez le collecteur à la main, vérifiez `/etc/cron.d/argus` |

Les lignes qui demandent une action sont répétées sous `TO CHECK` sur la sortie d'erreur.

## Lancer un collecteur à la main

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/argus-doctor.sh
tail -n 20 /var/log/argus.log
```


## Causes courantes

- **Aucune image après la première nuit.** Vérifiez que `/etc/cron.d/argus` existe et que cron s'exécute (`systemctl status cron`). Lancez `sudo /opt/argus/chart-daily.sh` et lisez son message.
- **`chart-daily.sh: no data file for 2026 in /srv/argus/2026 — nothing to plot.`** Aucun collecteur n'a écrit de fichier cette année. Un serveur sans aucune attaque n'en écrit pas. Lancez `sudo /opt/argus/collect-ssh.sh` pour collecter la veille.
- **SSH affiche 0 événement chaque jour.** `auth.log` est absent et `journald` contient les journaux sous un autre nom d'unité. Définissez `ARGUS_SSHD_UNIT="sshd"` dans `/etc/argus/argus.conf` (la valeur par défaut est `ssh`).
- **Moins d'attaques SSH que de bannissements Fail2Ban.** Argus compte une IP seulement après `ARGUS_SSH_THRESHOLD` tentatives échouées en une journée (5 par défaut), et Fail2Ban peut bannir plus tôt. Abaissez le seuil pour comparer.
- **`argus-chart: unknown view`.** Les vues sont `period`, `hourly` et `daily`.
- **`unknown series`.** Listez les noms avec `argus-chart period --list-series`.
- **`argus-fetch` signale un hôte.** Le serveur n'a pas répondu au premier essai, et `argus-fetch` ne fait pas de nouvelle tentative. Vérifiez l'alias, la clé et le pare-feu, puis relancez-le. Voir [desk.md](desk.md).
- **Permission refusée à l'écriture d'une image.** `/srv/argus` appartient à root : utilisez `sudo`, ou `--out DIR` dans votre répertoire personnel.
