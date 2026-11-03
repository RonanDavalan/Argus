# Argus

Pas de service permanent, pas de base de données, adapté aux machines de moins de 1 Go de RAM.

Argus compte les attaques contre vos serveurs, SSH de lui-même et, lorsqu'ils sont installés, les bannissements de Fail2Ban et de CrowdSec, et conserve l'historique sous forme de graphiques. Une tâche cron s'exécute chaque nuit, écrit des fichiers texte plats et dessine les graphiques. Rien ne tourne entre deux nuits.

Argus ne stocke ni n'affiche jamais l'adresse IP d'un attaquant, seulement des comptes par heure et par jour. Une **attaque** est une IP source qui atteint un nombre minimal de tentatives d'authentification échouées en une journée (5 par défaut), afin qu'un mot de passe mal saisi ne compte pas.

Grafana est une vue continue d'une infrastructure : un service qui tourne en permanence et peut être interrogé en direct. Argus est un instantané périodique de votre historique de sécurité : une image par nuit, lue quand vous le souhaitez. Grafana peut aussi agréger par semaine ou par année, au prix d'un service permanent, d'une base de données de séries temporelles et d'un tableau de bord à construire ; Argus n'a aucun des trois, ce qui lui permet de tenir sur un serveur de 1 Go.

## Installation en deux temps

Si vous installez habituellement un programme sur l'ordinateur avec lequel vous travaillez, ici c'est l'inverse. Le paquet va sur le **serveur**, la machine attaquée. Votre propre ordinateur, le poste de bureau, n'installe rien du paquet et ne reçoit que les images.

1. **Sur le serveur** (la machine attaquée), installez le paquet. Il compte les attaques et dessine les graphiques chaque nuit. Il n'y a rien à lancer ensuite.
2. **Sur votre poste de bureau** (l'ordinateur depuis lequel vous lisez), lancez `argus-fetch`. Il copie les images des graphiques depuis vos serveurs vers votre ordinateur.

Où se trouve chaque partie :

```
server.example.org (the server)           your desk
─────────────────────────────────         ──────────────────────────────
/opt/argus/        scripts                ~/.config/argus/hosts.conf
/etc/argus/        argus.conf                 the list of your servers
/srv/argus/<year>/ data and images        ~/argus-backup/<server>/<year>/images/
/usr/bin/argus-chart                          the copied charts
/usr/bin/argus-fetch   ── copies images ──►
```


Étape 1, sur le serveur (Debian ou Ubuntu) :

```bash
sudo apt install ./argus_1.0.0-12_all.deb
```


Étape 2, sur votre poste de bureau. Placez vos serveurs dans le fichier `~/.config/argus/hosts.conf`, un par ligne, sous la forme `<ssh alias>,<data directory>`, puis lancez `argus-fetch` :

```bash
mkdir -p ~/.config/argus
printf 'server.example.org,/srv/argus/\n' > ~/.config/argus/hosts.conf
argus-fetch
```


`argus-fetch` est installé par le même paquet. Sur un poste qui n'est pas une machine Debian, copiez le script unique `argus-fetch` depuis ce dépôt ; il ne lui faut que `bash`, `ssh` et `rsync`. Détails : [docs/install.md](docs/fr/install.md) et [docs/desk.md](docs/fr/desk.md).

## Les trois vues

`argus-chart` dessine un graphique pour la fenêtre que vous choisissez. Lancez-le sur le serveur. Chaque commande écrit un PNG dans `/srv/argus/<year>/images/` (ajoutez `--out DIR` pour écrire ailleurs, ce dont un utilisateur ordinaire a besoin).

- `argus-chart daily` est l'historique de l'année, un point par jour.
- `argus-chart period` est le compte de chaque série sur une fenêtre.
- `argus-chart hourly` est le compte par heure de la journée sur une fenêtre, de 00 à 23.

Dix fenêtres à copier :

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


Les séries sont dessinées côte à côte, jamais additionnées : SSH, chaque jail Fail2Ban et chaque scénario CrowdSec gardent leur propre ligne et leur propre couleur. Détails : [docs/charts.md](docs/fr/charts.md).

## Une connexion par hôte, pas de nouvelle tentative

`argus-fetch` ouvre **une connexion par hôte** et **ne réessaie jamais**. Beaucoup de serveurs bannissent une adresse après quelques tentatives de connexion échouées, si bien qu'une seconde tentative pourrait vous verrouiller dehors. Un hôte qui ne répond pas est signalé une fois, les autres hôtes sont quand même copiés, et le code de sortie est 1. Corrigez la cause (clé, alias, pare-feu, machine éteinte), puis relancez la commande à la main.

## Configuration

Tout fonctionne avec les valeurs par défaut. Pour en changer une, modifiez `/etc/argus/argus.conf` sur le serveur ; le fichier est lu par chaque script et livré avec chaque valeur commentée :

```bash
# /etc/argus/argus.conf
ARGUS_SSH_THRESHOLD=5          # failed attempts of one IP in one day that make an attack
ARGUS_LANG=en                  # chart language: en, fr, de or es
ARGUS_DATA_DIR="/srv/argus"    # where the data and the images are written
```


Les autres variables (chemins de journaux, taille des images, couleurs des séries) sont listées dans `man argus`.

## Vérifier que cela fonctionne

```bash
sudo /opt/argus/argus-doctor.sh
```


Il indique si chaque source (SSH, Fail2Ban, CrowdSec) a été collectée la veille. Voir [docs/troubleshooting.md](docs/fr/troubleshooting.md).

## Documentation

- [docs/install.md](docs/fr/install.md) : installer sur le serveur, arborescence, désinstallation
- [docs/desk.md](docs/fr/desk.md) : copier les graphiques sur votre poste de bureau et les lire
- [docs/charts.md](docs/fr/charts.md) : fenêtres, découpage, heure, séries, fuseau horaire, tranches `T00`
- [docs/troubleshooting.md](docs/fr/troubleshooting.md) : ce que dit `argus-doctor.sh` et que faire
- Pages de manuel : `man argus`, `man argus-chart`, `man argus-fetch` (sources dans `man/en/`)

---

## Crédits

Argus est le fruit d'une collaboration entre un humain et des modèles de langage, avec les rôles consignés tels qu'ils ont réellement été tenus. La liste complète est dans [CONTRIBUTORS.md](CONTRIBUTORS.md).

*   **Ronan Davalan** — Architecte et arbitre : scripts d'origine (2024), décisions, validation et essais.
*   **Claude Code (Anthropic)** — Développeur principal : collecteurs, rendu des graphiques, `argus-doctor.sh`, paquet Debian, documentation.
*   **Gemini (Google)** — Synthétiseur et co-rédacteur stratégique : planification et cadrage de la raison d'être du projet.
*   **Gemini (Google), GLM-5.3-Flash Free et Gemini 4 Argon** — Graphistes : identité visuelle du projet (marque, icône, favicon), adoptée par Ronan Davalan le 2026-11-02.
*   **DeepSeek** — Compagnon de terrain : installation de CrowdSec sur un serveur réel ayant servi à valider `collect-crowdsec.sh`.
*   **DeepSeek Flash** — Contenu du site en anglais, puis traductions française, allemande et espagnole de la documentation, des pages de manuel et du site.
*   **Muse Spark 1.3 Contributor** — Habillage du site : intégration du logo, du favicon et de l'image du graphe.
*   **gd2 :** frère défunt de Ronan Davalan. Il a appris Git à Ronan et son usage, conseillé ce projet, et fait la première modification extérieure à son README (2024-08-07).

---

## Licence

MIT — voir `LICENSE`.
