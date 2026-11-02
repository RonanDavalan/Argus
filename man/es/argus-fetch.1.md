---
title: ARGUS-FETCH
section: 1
header: Argus
---

# NOMBRE

argus-fetch - copia los gráficos Argus de sus servidores a este ordenador

# SINOPSIS

**argus-fetch** [**--config** *ARCHIVO*] [**--dest** *DIRECTORIO*] [**--only** *ALIAS*]

**argus-fetch** {**-h**|**--help**}

# DESCRIPCIÓN

Argus se ejecuta en los servidores y dibuja los gráficos allí. **argus-fetch** se ejecuta en su equipo de escritorio y copia las imágenes PNG de cada servidor a este ordenador.

Para cada servidor del archivo de configuración, **argus-fetch** abre **una** conexión ssh, sin pedir contraseña y con un tiempo de espera de conexión de 10 segundos, copia los archivos PNG de `<remote_path>/<year>/images/` y la cierra. Nunca reintenta: muchos servidores bloquean una dirección tras unos intentos de conexión fallidos. Un servidor que no responde se notifica en la salida de error estándar, los demás servidores se copian igualmente y el estado de salida es 1. Un archivo ya presente localmente nunca se sobrescribe, y no se borra nada.

# OPCIONES

**--config** *ARCHIVO*
:   Leer *ARCHIVO* en lugar de *~/.config/argus/hosts.conf*.

**--dest** *DIRECTORIO*
:   Copiar en *DIRECTORIO* en lugar de *~/argus-backup*.

**--only** *ALIAS*
:   Tratar solo el servidor de ese alias ssh.

**--local-source**
:   Modo de prueba. La ruta remota es un directorio de este ordenador, no se establece ninguna conexión ssh y el alias solo nombra el subdirectorio de destino.

**-h**, **--help**
:   Imprime el uso y sale.

# ARCHIVOS

*~/.config/argus/hosts.conf*
:   Un servidor por línea, `<ssh_alias>,<remote_path>`. El alias es un nombre **Host** de *~/.ssh/config* o una dirección **user@host**; la ruta es **ARGUS_DATA_DIR** en el servidor, */srv/argus/* por defecto. Las líneas vacías y las líneas que empiezan por **#** se ignoran.

`~/argus-backup/<ssh_alias>/<year>/images/`
:   Los gráficos copiados.

# CÓDIGOS DE SALIDA

**0**
:   Se copiaron todos los servidores.

**1**
:   Al menos un servidor falló, o falta el archivo de configuración.

**2**
:   Un uso incorrecto, o falta **rsync** o **ssh**.

# EJEMPLOS

Declare un servidor y luego copie:

```sh
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


Copie un servidor en otra carpeta:

```sh
argus-fetch --only server.example.org --dest ~/Documents/argus
```


# VÉASE TAMBIÉN

**argus**(7), **argus-chart**(1)
