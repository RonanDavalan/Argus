# Solución de problemas

Un gráfico sin ataque puede significar un día tranquilo o un recolector que se detuvo. Los archivos de datos no permiten distinguirlos, porque un día sin ataque no escribe ninguna línea. `argus-doctor.sh` sí puede: cada recolector escribe una línea al día en `/srv/argus/<year>/.heartbeat/<source>.txt`, `<date> <number of events>`, incluso cuando el número es 0.

## Ejecutar la comprobación

```bash
sudo /opt/argus/argus-doctor.sh
```


La tarea cron lo ejecuta cada noche a las 00:20 y añade la salida a `/var/log/argus.log`. El código de salida es 0 cuando no hay nada que informar, 1 en caso contrario. Un servidor sano imprime:

```
== Source availability ==

== Heartbeats (2026) ==
  ssh : ok
    -> up to date, yesterday: 12 event(s)
  fail2ban : absent
  crowdsec : absent

Nothing to report.
```


## Qué significa cada línea

`<source> : ok` o `absent` indica si la fuente puede leerse ahora: `auth.log` o `journald` para `ssh`, `fail2ban-client` y su registro para `fail2ban`, `cscli` y `jq` para `crowdsec`. `absent` para Fail2Ban o CrowdSec es normal cuando no los ejecuta.

| Línea bajo la fuente | Significado | Qué hacer |
|---|---|---|
| `up to date, yesterday: N event(s)` | recogida ayer, N eventos (0 es un día tranquilo) | nada |
| `last confirmed on DATE (no entry for yesterday)` | el recolector no se ejecutó o falló desde DATE | mire `/var/log/argus.log`, ejecute el recolector a mano |
| `never collected` | no hay archivo de latido, aunque la fuente es legible | ejecute el recolector a mano, compruebe `/etc/cron.d/argus` |

Las líneas que requieren acción se repiten bajo `TO CHECK` en la salida de error.

## Ejecutar un recolector a mano

```bash
sudo /opt/argus/collect-ssh.sh
sudo /opt/argus/argus-doctor.sh
tail -n 20 /var/log/argus.log
```


## Causas frecuentes

- **Ninguna imagen tras la primera noche.** Compruebe que `/etc/cron.d/argus` existe y que cron se ejecuta (`systemctl status cron`). Ejecute `sudo /opt/argus/chart-daily.sh` y lea su mensaje.
- **`chart-daily.sh: no data file for 2026 in /srv/argus/2026 — nothing to plot.`** Ningún recolector ha escrito un archivo este año. Un servidor sin ningún ataque no escribe ninguno. Ejecute `sudo /opt/argus/collect-ssh.sh` para recoger el día de ayer.
- **SSH muestra 0 eventos cada día.** `auth.log` no existe y `journald` guarda los registros bajo otro nombre de unidad. Defina `ARGUS_SSHD_UNIT="sshd"` en `/etc/argus/argus.conf` (el valor por defecto es `ssh`).
- **Menos ataques SSH que bloqueos de Fail2Ban.** Argus cuenta una IP solo tras `ARGUS_SSH_THRESHOLD` intentos fallidos en un día (5 por defecto), y Fail2Ban puede bloquear antes. Baje el umbral para comparar.
- **`argus-chart: unknown view`.** Las vistas son `period`, `hourly` y `daily`.
- **`unknown series`.** Enumere los nombres con `argus-chart period --list-series`.
- **`argus-fetch` informa de un host.** El servidor no respondió al primer intento, y `argus-fetch` no reintenta. Compruebe el alias, la clave y el cortafuegos, y vuelva a ejecutarlo. Véase [desk.md](desk.md).
- **Permiso denegado al escribir una imagen.** `/srv/argus` pertenece a root: use `sudo`, o `--out DIR` en su directorio personal.
