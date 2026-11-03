# Argus

Sin servicio permanente, sin base de datos, adecuado para máquinas con menos de 1 GB de RAM.

Argus cuenta los ataques contra sus servidores, SSH por sí solo y, cuando están instalados, los bloqueos de Fail2Ban y CrowdSec, y conserva el historial como gráficos. Una tarea cron se ejecuta cada noche, escribe archivos de texto plano y dibuja los gráficos. Entre dos noches no se ejecuta nada.

Argus nunca almacena ni muestra la dirección IP de un atacante, solo recuentos por hora y por día. Un **ataque** es una IP de origen que alcanza un número mínimo de intentos de autenticación fallidos en un día (5 por defecto), de modo que una contraseña mal escrita no cuenta.

Grafana es una vista continua de una infraestructura: un servicio que se ejecuta todo el tiempo y puede consultarse en directo. Argus es una instantánea periódica de su historial de seguridad: una imagen por noche, leída cuando usted quiera. Grafana también puede agregar por semana o por año, a costa de un servicio permanente, una base de datos de series temporales y un panel que construir; Argus no tiene ninguno de los tres, por eso cabe en un servidor de 1 GB.

## Instalación en dos tiempos

Si normalmente instala un programa en el ordenador en el que trabaja, aquí es al revés. El paquete va en el **servidor**, la máquina atacada. Su propio ordenador, el equipo de escritorio, no instala nada del paquete y solo recibe las imágenes.

1. **En el servidor** (la máquina atacada), instale el paquete. Cuenta los ataques y dibuja los gráficos cada noche. Después no hay nada que lanzar.
2. **En su equipo de escritorio** (el ordenador desde el que lee), ejecute `argus-fetch`. Copia las imágenes de los gráficos de sus servidores a su ordenador.

Dónde está cada parte:

```
server.example.org (the server)           your desk
─────────────────────────────────         ──────────────────────────────
/opt/argus/        scripts                ~/.config/argus/hosts.conf
/etc/argus/        argus.conf                 the list of your servers
/srv/argus/<year>/ data and images        ~/argus-backup/<server>/<year>/images/
/usr/bin/argus-chart                          the copied charts
/usr/bin/argus-fetch   ── copies images ──►
```


Paso 1, en el servidor (Debian o Ubuntu):

```bash
sudo apt install ./argus_1.0.0-12_all.deb
```


Paso 2, en su equipo de escritorio. Ponga sus servidores en el archivo `~/.config/argus/hosts.conf`, uno por línea, con la forma `<ssh alias>,<data directory>`, y luego ejecute `argus-fetch`:

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


`argus-fetch` lo instala el mismo paquete. En un equipo que no sea una máquina Debian, copie el único script `argus-fetch` desde este repositorio; solo necesita `bash`, `ssh` y `rsync`. Detalles: [docs/install.md](docs/es/install.md) y [docs/desk.md](docs/es/desk.md).

## Las tres vistas

`argus-chart` dibuja un gráfico para la ventana que usted elija. Ejecútelo en el servidor. Cada comando escribe un PNG en `/srv/argus/<year>/images/` (añada `--out DIR` para escribir en otro sitio, lo que necesita un usuario normal).

- `argus-chart daily` es el historial del año, un punto por día.
- `argus-chart period` es el recuento de cada serie en una ventana.
- `argus-chart hourly` es el recuento por hora del día en una ventana, de 00 a 23.

Diez ventanas que copiar:

```bash
argus-chart period --day 2026-10-30                       # one day, one point per hour
argus-chart period --week 2026-W44                        # ISO week, Monday to Sunday
argus-chart period --month 2026-10                        # one calendar month
argus-chart period --quarter 2026-Q4                      # one quarter
argus-chart period --year 2025                            # one year
argus-chart period --from 2025-12-01 --to 2026-01-31      # a range over two years
argus-chart period --month 2026-10 --split week           # one PNG per week of the month
argus-chart period --week 2026-W44 --series ssh_direct    # one series only
argus-chart hourly --week 2026-W44                        # which hours are attacked
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd
```


Las series se dibujan una al lado de otra, nunca sumadas: SSH, cada jail de Fail2Ban y cada escenario de CrowdSec conservan su propia línea y su propio color. Detalles: [docs/charts.md](docs/es/charts.md).

## Una conexión por host, sin reintento

`argus-fetch` abre **una conexión por host** y **nunca reintenta**. Muchos servidores bloquean una dirección tras unos intentos de conexión fallidos, así que un segundo intento podría dejarle sin acceso. Un host que no responde se notifica una vez, los demás hosts se copian igualmente y el código de salida es 1. Corrija la causa (clave, alias, cortafuegos, máquina apagada) y vuelva a ejecutarlo a mano.

## Configuración

Todo funciona con los valores por defecto. Para cambiar uno, edite `/etc/argus/argus.conf` en el servidor; el archivo lo lee cada script y se entrega con cada valor comentado:

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=5          # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_DATA_DIR="/srv/argus"    # where the data and the images are written
```


Las demás variables (rutas de registros, tamaño de imagen, colores de las series) se enumeran en `man argus`.

## Comprobar que funciona

```bash
sudo /opt/argus/argus-doctor.sh
```


Indica si cada fuente (SSH, Fail2Ban, CrowdSec) se recogió ayer. Véase [docs/troubleshooting.md](docs/es/troubleshooting.md).

## Documentación

- [docs/install.md](docs/es/install.md): instalar en el servidor, estructura, desinstalación
- [docs/desk.md](docs/es/desk.md): traer los gráficos al equipo de escritorio y leerlos
- [docs/charts.md](docs/es/charts.md): ventanas, división, hora, series, zona horaria, franjas `T00`
- [docs/troubleshooting.md](docs/es/troubleshooting.md): qué dice `argus-doctor.sh` y qué hacer
- Páginas de manual: `man argus`, `man argus-chart`, `man argus-fetch` (fuentes en `man/en/`)

---

## Créditos

Argus es el resultado de una colaboración entre un humano y varios modelos de lenguaje, con los roles escritos tal como se desempeñaron realmente. La lista completa está en [CONTRIBUTORS.md](CONTRIBUTORS.md).

*   **Ronan Davalan** — Arquitecto y árbitro: scripts originales (2024), decisiones, validación y pruebas.
*   **Claude Code (Anthropic)** — Desarrollador principal: recolectores, renderizado de gráficos, `argus-doctor.sh`, paquete Debian, documentación.
*   **Gemini (Google)** — Sintetizador y coautor estratégico: planificación y encuadre del propósito del proyecto.
*   **Gemini (Google), GLM-5.3-Flash Free y Gemini 4 Argon** — Diseñadores gráficos: identidad visual del proyecto (marca, icono, favicon), adoptada por Ronan Davalan el 2026-11-02.
*   **DeepSeek** — Compañero de campo: instalación de CrowdSec en un servidor real que sirvió para validar `collect-crowdsec.sh`.
*   **DeepSeek Flash** — Contenido del sitio en inglés, luego traducciones al francés, alemán y español de la documentación, las páginas de manual y el sitio.
*   **Muse Spark 1.3 Contributor** — Diseño del sitio: integración del logo, del favicon y de la imagen del gráfico.
*   **gd2:** hermano fallecido de Ronan Davalan. Le enseñó Git a Ronan y su uso, asesoró este proyecto e hizo la primera modificación externa de su README (2024-08-07).

---

## Licencia

MIT — véase `LICENSE`.
