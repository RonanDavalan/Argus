# Traer los gráficos al equipo de escritorio y leerlos

Argus se ejecuta en sus servidores y dibuja los gráficos allí. `argus-fetch` copia las imágenes al ordenador en el que trabaja. No se envía nada desde el servidor: usted trae las imágenes cuando quiere.

## Lo que obtiene

```
~/.config/argus/hosts.conf              the servers to copy, one per line
~/argus-backup/
└── server.example.org/                 one folder per ssh alias
    └── 2026/
        └── images/
            ├── 2026-11-02_argus_4k.png
            └── 2026-11-02_argus_period_week-2026-W44.png
```


## Requisitos

`bash`, `ssh` y `rsync` en el equipo de escritorio. El paquete instala `argus-fetch` en `/usr/bin`; en otro sistema, copie el único archivo `argus-fetch` del repositorio a una carpeta de su `PATH`. Su `ssh` ya debe iniciar sesión en el servidor con una clave, sin pedir contraseña: `argus-fetch` nunca la pide.

## Declarar los servidores

Un servidor por línea, `<ssh alias>,<data directory>`. El alias es un nombre de `Host` de `~/.ssh/config` (o `user@host`); el directorio es `ARGUS_DATA_DIR` en ese servidor, `/srv/argus/` por defecto.

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\nbackup.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
cat ~/.config/argus/hosts.conf
```


Las líneas vacías y las líneas que empiezan por `#` se ignoran. El repositorio incluye `hosts.conf.example`.

## Copiar

```bash
argus-fetch
```


Para cada servidor abre **una** conexión, copia los archivos PNG de `<directory>/<year>/images/` y la cierra. Un archivo que ya esté en su equipo de escritorio nunca se sobrescribe y no se borra nada. Ejecútelo tantas veces como quiera: solo se copian las imágenes nuevas.

Para copiar un solo servidor o poner las copias en otro sitio:

```bash
argus-fetch --only server.example.org
argus-fetch --dest ~/Documents/argus
```


## Una conexión, sin reintento

Si un servidor no responde, `argus-fetch` lo indica una vez en la salida de error, continúa con los demás servidores y termina con el código de salida 1. Nunca reintenta, porque muchos servidores bloquean una dirección tras unos intentos de conexión fallidos. Encuentre la causa (clave, alias, cortafuegos, servidor apagado) y vuelva a ejecutar el comando usted mismo.

## Leer los gráficos

Abra las imágenes con cualquier visor:

```bash
xdg-open ~/argus-backup/server.example.org/2026/images/
```


Un gráfico muestra una línea por serie. En una ventana de hasta 31 puntos, el recuento exacto se escribe junto a cada punto. Una vista que aún no existe (otra semana, un mes por hora) se dibuja en el servidor, como root para que la imagen llegue a la carpeta de imágenes:

```bash
ssh server.example.org
sudo argus-chart period --week 2026-W44
```


El siguiente `argus-fetch` copia la imagen nueva con las demás. Véase [charts.md](charts.md) para las ventanas que puede pedir.
