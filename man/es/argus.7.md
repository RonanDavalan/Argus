---
title: ARGUS
section: 7
header: Argus
---

# NOMBRE

argus - cuenta los ataques contra un servidor y conserva su historial como gráficos

# DESCRIPCIÓN

Sin servicio permanente, sin base de datos, adecuado para máquinas con menos de 1 GB de RAM.

Argus cuenta los ataques SSH de un servidor y, cuando están instalados, los bloqueos de Fail2Ban y CrowdSec. Una tarea cron se ejecuta cada noche, escribe archivos de texto plano y dibuja gráficos. Entre dos noches no se ejecuta nada.
Argus nunca almacena ni muestra la dirección IP de un atacante, solo recuentos por hora y por día. Un ataque es una IP de origen que alcanza **ARGUS_SSH_THRESHOLD** intentos de autenticación fallidos en un día.

Grafana es una vista continua de una infraestructura: un servicio que se ejecuta todo el tiempo y puede consultarse en directo. Argus es una instantánea periódica del historial de seguridad: una imagen por noche, leída cuando usted quiera.

# DOS TIEMPOS

El paquete se instala en el **servidor**, la máquina atacada, no en el equipo de escritorio (el ordenador desde el que lee).

1. En el servidor, el paquete cuenta los ataques y dibuja los gráficos cada noche.
2. En el equipo de escritorio, **argus-fetch**(1) copia las imágenes de los servidores al ordenador en el que las lee.

**argus-chart**(1) dibuja otras vistas de los mismos datos, en el servidor.

# ARCHIVOS

*/opt/argus/*
:   Los scripts: *collect-ssh.sh*, *collect-fail2ban.sh*, *collect-crowdsec.sh*, *chart-daily.sh*, *chart-period.sh*, *chart-hourly.sh*, *argus-lib.sh*, *argus-doctor.sh*.

*/etc/argus/argus.conf*
:   Ajustes opcionales, un archivo de shell que lee cada script. Todas las líneas están comentadas.

*/etc/cron.d/argus*
:   Recogida a las 00:05, gráficos a las 00:15, comprobación de estado a las 00:20.

`/srv/argus/<year>/<series>_<year>.txt`
:   Una línea por hora con un ataque, **\<count\> \<YYYY-MM-DD\>T\<HH\>**. Una serie es el nombre del archivo sin el año: *ssh_direct*, *ip_ban_\<jail\>*.

`/srv/argus/<year>/.heartbeat/`
:   Una línea al día por recolector, leída por *argus-doctor.sh*.

`/srv/argus/<year>/images/`
:   Los gráficos PNG.

*/var/log/argus.log*
:   Salida de las tareas cron.

# ENTORNO

Las variables se definen en */etc/argus/argus.conf*. Una variable ya definida en el entorno prevalece sobre el archivo.

**ARGUS_DATA_DIR**
:   Datos e imágenes. Por defecto */srv/argus*.

**ARGUS_SSH_THRESHOLD**
:   Intentos fallidos de una IP en un día que constituyen un ataque. Por defecto 5.

**ARGUS_AUTHLOG**
:   Registro SSH. Por defecto */var/log/auth.log*; cuando no existe, se lee el journal.

**ARGUS_SSHD_UNIT**
:   Unidad de systemd leída del journal. Por defecto *ssh*.

**ARGUS_FAIL2BAN_LOG**
:   Registro de Fail2Ban. Por defecto */var/log/fail2ban.log*.

**ARGUS_DATA_OWNER**
:   Usuario propietario de los archivos tras cada escritura.

**ARGUS_LANG**
:   Idioma de los gráficos: *en* (por defecto), *fr*, *de* o *es*.

**ARGUS_IMG_WIDTH**, **ARGUS_IMG_HEIGHT**
:   Tamaño de la imagen en píxeles. Por defecto 3840 y 2160.

**ARGUS_COULEUR_**`<series>`
:   Color de una serie, cualquier nombre de color de gnuplot. En el nombre de la variable, los guiones de la serie se convierten en guiones bajos.

**ARGUS_CONF**
:   Ruta del archivo de configuración en lugar de */etc/argus/argus.conf*.

# EJEMPLOS

Compruebe que cada recolector se ejecutó ayer:

```sh
sudo /opt/argus/argus-doctor.sh
```


Dibuje el recuento del cuarto trimestre de 2026 como un solo gráfico:

```sh
sudo argus-chart period --quarter 2026-Q4
```


# VÉASE TAMBIÉN

**argus-chart**(1), **argus-fetch**(1)
