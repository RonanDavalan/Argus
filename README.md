# Projet d'Analyse Fail2Ban

## Description
Ce projet fournit des scripts pour analyser et visualiser les tentatives de connexion bloquées par Fail2Ban sur un serveur. Il génère des rapports quotidiens et des graphiques pour aider à comprendre les tendances des attaques et l'efficacité de la protection Fail2Ban.

## Fonctionnalités
- Extraction quotidienne des adresses IP bannies à partir des logs Fail2Ban
- Génération de graphiques montrant le nombre d'adresses IP bannies par jour pour chaque service
- Organisation des données et graphiques par année
- Automatisation via des tâches cron

## Prérequis
- Fail2Ban installé et configuré sur le serveur
- Bash
- Gnuplot
- Accès aux logs système (rsyslog ou journalctl)

## Structure du Projet
```
/
├── opt/
│   └── script_principal_rsyslog.sh (ou script_principal_journalctl.sh)
├── home/user/
│   ├── fail2ban_gnuplot_couleur.gp
│   └── [ANNÉE]/
│       ├── ip_ban_[SERVICE]_[ANNÉE].txt
│       └── images/
│           └── [DATE]_ip_ban_fail2ban_4k.png
```

## Installation et Configuration

1. Placez `script_principal_rsyslog.sh` (ou `script_principal_journalctl.sh`) dans `/opt/`.
2. Placez `fail2ban_gnuplot_couleur.gp` dans le répertoire home de l'utilisateur.
3. Créez les répertoires nécessaires pour les données et les images.
4. Configurez les variables dans les scripts :
   - Dans `script_principal_rsyslog.sh` :
     ```bash
     repertoire_destination="$HOME/$(date -d yesterday +%Y)"
     utilisateur="votre_utilisateur"
     groupe="votre_groupe"
     ```
   - Assurez-vous que les chemins dans `fail2ban_gnuplot_couleur.gp` correspondent à votre structure de répertoires.

5. Configurez les tâches cron :
   ```
   # Pour l'extraction des données
   5 0 * * * /opt/script_principal_rsyslog.sh >> /var/log/suivi_bannissements_fail2ban.log 2>&1

   # Pour la génération du graphique
   15 0 * * * cd /home/user && gnuplot fail2ban_gnuplot_couleur.gp && chmod 600 /home/user/[ANNÉE]/images/*
   ```

## Utilisation
Une fois configuré, le système fonctionnera automatiquement :
1. Chaque jour à 00:05, le script d'extraction des données s'exécutera.
2. À 00:15, le script Gnuplot générera le graphique quotidien.

Les résultats seront stockés dans les répertoires appropriés, organisés par année.

## Personnalisation
- Modifiez `fail2ban_gnuplot_couleur.gp` pour ajuster l'apparence des graphiques.
- Ajustez les horaires des tâches cron selon vos besoins.

## Sécurité
- Les fichiers de données et les images sont créés avec des permissions restreintes (600).
- Assurez-vous que seuls les utilisateurs autorisés ont accès aux scripts et aux données générées.

## Contribution
Ce projet a été développé par Ronan DAVALAN. Les contributions sont les bienvenues. Veuillez soumettre des pull requests pour toute amélioration ou correction de bugs.

## Licence
Ce projet est sous licence MIT.

## Remerciements
Ce projet a été développé avec l'aide de divers assistants IA, notamment ChatGPT, Claude AI et Perplexity AI.
