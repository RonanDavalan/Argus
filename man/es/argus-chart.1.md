---
title: ARGUS-CHART
section: 1
header: Argus
---

# NOMBRE

argus-chart - dibuja los gráficos Argus de un servidor

# SINOPSIS

**argus-chart period** [*ventana*] [*opciones*]

**argus-chart hourly** [*ventana*] [*opciones*]

**argus-chart daily** [*año*]

**argus-chart** {**-h**|**--help**}

# DESCRIPCIÓN

**argus-chart** es el punto de entrada único de los gráficos. Pasa las opciones que siguen al nombre de la vista, sin cambios, al script de esa vista, buscado junto al comando y luego en */opt/argus*. Ejecútelo en el servidor, como root para escribir en */srv/argus*, o como usuario normal con **--out**.

**period**
:   El recuento de cada serie en una ventana, una línea por serie. Script *chart-period.sh*.

**hourly**
:   El recuento de cada serie a cada hora del día, de 00 a 23, sumado en una ventana. La hora es la hora local del servidor. Script *chart-hourly.sh*.

**daily**
:   El historial de un año, un punto por día, el año en curso por defecto. Script *chart-daily.sh*.

Las series se superponen, nunca se suman.

# VENTANA

Una de las siguientes, para **period** y **hourly**. Sin ninguna, la ventana es el año en curso. Una ventana que abarca dos años lee los datos de ambos.

**--day** *YYYY-MM-DD*
:   Un día.

**--week** *YYYY-Www*
:   Una semana ISO 8601, de lunes a domingo.

**--month** *YYYY-MM*
:   Un mes natural.

**--quarter** *YYYY-Qn*
:   Un trimestre, *n* de 1 a 4.

**--year** *YYYY*
:   Un año natural.

**--from** *YYYY-MM-DD* **--to** *YYYY-MM-DD*
:   Un rango, ambos días incluidos.

# OPCIONES

**--series** *a,b*
:   Solo estas series, nombradas sin el sufijo del año. Un nombre desconocido detiene el comando con el estado de salida 2.

**--list-series**
:   Imprime las series de la ventana y sale. Con **hourly**, solo las series que se dibujan.

**--split** *week*|*month*
:   Solo **period**. Un gráfico por semana ISO, o por mes natural, de la ventana. Los subperiodos se recortan a la ventana.

**--out** *DIR*
:   Directorio de salida. Por defecto `/srv/argus/<year>/images`.

**--print-data**
:   Imprime en la salida estándar la tabla que hay detrás del gráfico, separada por tabulaciones, línea de cabecera que empieza por **#**, y sale. No se dibuja nada.

**-h**, **--help**
:   Imprime el uso y sale. Tras un nombre de vista, imprime las opciones de esa vista.

# ARCHIVOS

`<out>/<YYYY-MM-DD>_argus_<view>_<window>.png`
:   El gráfico. La fecha es hoy; la ventana es, por ejemplo, *week-2026-W44*, *month-2026-10* o *range-2025-12-01_2026-01-31*. Con **--split**, es `<parent>_<sub-period>`, por ejemplo *month-2026-10_week-2026-W41*.

# CÓDIGOS DE SALIDA

**0**
:   Hecho.

**2**
:   Un uso incorrecto, una serie desconocida o una vista que esta versión no tiene.

Cualquier otro estado es el del script que se ejecutó.

# EJEMPLOS

Una semana, luego la misma semana por hora:

```sh
argus-chart period --week 2026-W44 --out ~/argus-out
argus-chart hourly --week 2026-W44 --out ~/argus-out
```


Un gráfico por semana de un mes, solo para SSH:

```sh
argus-chart period --month 2026-10 --split week --series ssh_direct --out ~/argus-out
```


# VÉASE TAMBIÉN

**argus**(7), **argus-fetch**(1)
