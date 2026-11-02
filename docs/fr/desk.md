# Copier les graphiques sur votre poste de bureau et les lire

Argus tourne sur vos serveurs et y dessine les graphiques. `argus-fetch` copie les images sur l'ordinateur avec lequel vous travaillez. Rien n'est envoyé depuis le serveur : c'est vous qui venez chercher les images, quand vous le souhaitez.

## Ce que vous obtenez

```
~/.config/argus/hosts.conf              the servers to copy, one per line
~/argus-backup/
└── server.example.org/                 one folder per ssh alias
    └── 2026/
        └── images/
            ├── 2026-11-02_argus_4k.png
            └── 2026-11-02_argus_period_week-2026-W44.png
```


## Prérequis

`bash`, `ssh` et `rsync` sur le poste de bureau. Le paquet installe `argus-fetch` dans `/usr/bin` ; sur un autre système, copiez le fichier unique `argus-fetch` depuis le dépôt vers un dossier de votre `PATH`. Votre `ssh` doit déjà se connecter au serveur avec une clé, sans demande de mot de passe : `argus-fetch` n'en demande jamais.

## Déclarer les serveurs

Un serveur par ligne, `<ssh alias>,<data directory>`. L'alias est un nom de `Host` de `~/.ssh/config` (ou `user@host`) ; le répertoire est `ARGUS_DATA_DIR` sur ce serveur, `/srv/argus/` par défaut.

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\nbackup.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
cat ~/.config/argus/hosts.conf
```


Les lignes vides et les lignes commençant par `#` sont ignorées. Le dépôt fournit `hosts.conf.example`.

## Copie

```bash
argus-fetch
```


Pour chaque serveur, il ouvre **une** connexion, copie les fichiers PNG de `<directory>/<year>/images/`, puis la ferme. Un fichier déjà présent sur votre poste de bureau n'est jamais écrasé et rien n'est supprimé. Lancez-le aussi souvent que vous le souhaitez : seules les nouvelles images sont copiées.

Pour ne copier qu'un serveur, ou placer les copies ailleurs :

```bash
argus-fetch --only server.example.org
argus-fetch --dest ~/Documents/argus
```


## Une connexion, pas de nouvelle tentative

Si un serveur ne répond pas, `argus-fetch` le signale une fois sur la sortie d'erreur, continue avec les autres serveurs et se termine avec le code de sortie 1. Il ne réessaie jamais, car beaucoup de serveurs bannissent une adresse après quelques tentatives de connexion échouées. Trouvez la cause (clé, alias, pare-feu, serveur éteint), puis relancez la commande vous-même.

## Lire les graphiques

Ouvrez les images avec n'importe quelle visionneuse :

```bash
xdg-open ~/argus-backup/server.example.org/2026/images/
```


Un graphique montre une ligne par série. Sur une fenêtre d'au plus 31 points, le compte exact est écrit à chaque point. Une vue qui n'existe pas encore (une autre semaine, un mois par heure) se dessine sur le serveur, en root pour que l'image arrive dans le dossier des images :

```bash
ssh server.example.org
sudo argus-chart period --week 2026-W44
```


Le prochain `argus-fetch` copie la nouvelle image avec les autres. Voir [charts.md](charts.md) pour les fenêtres que vous pouvez demander.
