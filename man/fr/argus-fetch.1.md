---
title: ARGUS-FETCH
section: 1
header: Argus
---

# NOM

argus-fetch - copie les graphiques Argus de vos serveurs vers cet ordinateur

# SYNOPSIS

**argus-fetch** [**--config** *FICHIER*] [**--dest** *RÉPERTOIRE*] [**--only** *ALIAS*]

**argus-fetch** {**-h**|**--help**}

# DESCRIPTION

Argus tourne sur les serveurs et y dessine les graphiques. **argus-fetch** tourne sur votre poste de bureau et copie les images PNG de chaque serveur vers cet ordinateur.

Pour chaque serveur du fichier de configuration, **argus-fetch** ouvre **une** connexion ssh, sans demande de mot de passe et avec un délai de connexion de 10 secondes, copie les fichiers PNG de `<remote_path>/<year>/images/` et ferme la connexion. Il ne réessaie jamais : beaucoup de serveurs bannissent une adresse après quelques tentatives de connexion échouées. Un serveur qui ne répond pas est signalé sur la sortie d'erreur, les autres serveurs sont quand même copiés, et le code de sortie est 1. Un fichier déjà présent localement n'est jamais écrasé, et rien n'est supprimé.

# OPTIONS

**--config** *FICHIER*
:   Lire *FICHIER* au lieu de *~/.config/argus/hosts.conf*.

**--dest** *RÉPERTOIRE*
:   Copier dans *RÉPERTOIRE* au lieu de *~/argus-backup*.

**--only** *ALIAS*
:   Ne traiter que le serveur de cet alias ssh.

**--local-source**
:   Mode de test. Le chemin distant est un répertoire de cet ordinateur, aucune connexion ssh n'est établie, et l'alias ne nomme que le sous-répertoire de destination.

**-h**, **--help**
:   Imprimer l'usage et quitter.

# FICHIERS

*~/.config/argus/hosts.conf*
:   Un serveur par ligne, `<ssh_alias>,<remote_path>`. L'alias est un nom **Host** de *~/.ssh/config* ou une adresse **user@host** ; le chemin est **ARGUS_DATA_DIR** sur le serveur, */srv/argus/* par défaut. Les lignes vides et les lignes commençant par **#** sont ignorées.

`~/argus-backup/<ssh_alias>/<year>/images/`
:   Les graphiques copiés.

# CODES DE SORTIE

**0**
:   Tous les serveurs ont été copiés.

**1**
:   Au moins un serveur a échoué, ou le fichier de configuration manque.

**2**
:   Un usage incorrect, ou **rsync** ou **ssh** manque.

# EXEMPLES

Déclarez un serveur, puis copiez :

```sh
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


Copiez un serveur dans un autre dossier :

```sh
argus-fetch --only server.example.org --dest ~/Documents/argus
```


# VOIR AUSSI

**argus**(7), **argus-chart**(1)
