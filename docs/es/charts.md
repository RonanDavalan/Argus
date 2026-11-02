# Gráficos: ventanas, división, hora, series

`argus-chart` tiene tres vistas. Ejecútelo en el servidor, como root para escribir en `/srv/argus/<year>/images/`, o como usuario normal con `--out DIR`.

```
argus-chart daily  [YEAR]               one point per day, the whole year
argus-chart period [window] [options]   one line per series over a window
argus-chart hourly [window] [options]   24 positions, 00 to 23, per series
```


Cada archivo se llama `<today>_argus_<view>_<window>.png`, por ejemplo `2026-11-02_argus_period_week-2026-W44.png`.

## Ventanas

`period` y `hourly` aceptan las mismas ventanas. Sin ninguna, usan el año en curso.

| Opción | Ventana | Ejemplo |
|---|---|---|
| `--day YYYY-MM-DD` | un día | `--day 2026-10-30` |
| `--week YYYY-Www` | semana ISO, de lunes a domingo | `--week 2026-W44` |
| `--month YYYY-MM` | mes natural | `--month 2026-10` |
| `--quarter YYYY-Qn` | trimestre, `n` de 1 a 4 | `--quarter 2026-Q4` |
| `--year YYYY` | año natural | `--year 2025` |
| `--from D --to D` | rango, ambos días incluidos | `--from 2025-12-01 --to 2026-01-31` |

Las semanas siguen la norma ISO 8601: la semana 1 de 2027 empieza el lunes 2027-01-04, y 2026 tiene una semana 53. Una ventana que abarca dos años lee los datos de ambos.

```bash
argus-chart period --day 2026-10-30 --out ~/argus-out
argus-chart period --from 2025-12-01 --to 2026-01-31 --out ~/argus-out
```


## Dividir una ventana larga

`--split` dibuja un gráfico por subperiodo en lugar de un solo gráfico largo:

```bash
argus-chart period --month 2026-10 --split week --out ~/argus-out
argus-chart period --year 2026 --split month --out ~/argus-out
```


`--split week` conviene a un mes o a un trimestre, `--split month` a un trimestre o a un año. El primer comando escribe un archivo por semana ISO que toca octubre, cada uno recortado a la ventana, llamado `…_month-2026-10_week-2026-W41.png`.

## La hora del día

`hourly` suma, para cada serie, los ataques vistos a cada hora de la ventana y dibuja 24 posiciones. Muestra a qué horas del día se le ataca, no en qué días.

```bash
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


La hora es la **hora local del servidor**, tal como la escriben los recolectores. Es la hora a la que se vio el ataque en los registros, no la hora a la que empezó. El título dice «local server time». El cambio al horario de verano desplaza una hora en un día, un efecto que se difumina a lo largo de una semana completa.

## Las series se superponen, nunca se suman

Cada línea de la imagen es una serie: `ssh_direct` para SSH, `ip_ban_<jail>` para cada jail de Fail2Ban, `ip_ban_<scenario>` para cada escenario de CrowdSec. Su nombre es el nombre del archivo sin el año, así que `ssh_direct_2026.txt` pertenece a `ssh_direct`.

Argus no inventa una puntuación a partir de herramientas distintas. Cada serie conserva el mismo color de un año a otro, definido con `ARGUS_COULEUR_<series>` o tomado de un hash del nombre.

```bash
argus-chart period --week 2026-W44 --list-series
argus-chart period --week 2026-W44 --series ssh_direct
argus-chart hourly --month 2026-10 --series ssh_direct,ip_ban_sshd --out ~/argus-out
```


Un nombre desconocido en `--series` detiene el comando con el código de salida 2 y enumera los nombres disponibles.

## Leer los números en lugar de la imagen

`--print-data` imprime en la salida estándar la tabla que hay detrás del gráfico (separada por tabulaciones, cabecera que empieza por `#`) y no dibuja nada:

```bash
argus-chart period --week 2026-W44 --print-data
argus-chart hourly --day 2026-10-30 --print-data
```


## Franjas a la hora 00 (`T00`)

Una línea de datos es `<count> <date>T<hour>`, por ejemplo `492 2026-10-30T14`. Los archivos anteriores a la recogida por horas contienen una línea por día, todas escritas como `T00`. Una serie formada solo por franjas `T00` no tiene información de hora, así que `hourly` la excluye en lugar de dibujar una barra a medianoche. Imprime el mensaje `series 'legacy' excluded: all its slices are at hour 00 (daily data, no hourly depth)` en la salida de error y escribe `excluded series: no hourly data: legacy` en el título del gráfico. `period` y `daily` la siguen dibujando como puntos diarios.

## Idioma de los gráficos

`ARGUS_LANG` define los títulos y los ejes: `en` (por defecto), `fr`, `de` o `es`.

```bash
ARGUS_LANG=de argus-chart period --week 2026-W44 --out ~/argus-out
```

