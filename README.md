# Chromie Wishlist (WoW 3.3.5a)

Addon conçu pour ChromieCraft. Il utilise les tables de butin de **AtlasLoot Enhanced 5.11** déjà installées.

## Utilisation

- La fenêtre permet de parcourir à tout moment les instances Classic, BC et WotLK d'AtlasLoot.
- L'ouverture automatique à l'entrée d'une instance est désactivée par défaut.
- Seuls les équipements utilisables par la classe sont affichés, sans filtrage de spécialisation.
- La case `Filtre <classe>` de la fenêtre permet de basculer instantanément entre les objets adaptés à la classe et tous les objets.
- La barre de recherche retrouve un objet par nom ou ID dans toutes les tables d'instances.
- Un bouton déplaçable autour de la minimap ouvre l'addon avec le clic gauche et la wishlist avec le clic droit.
- Le bouton `FR` / `EN` dans l'en-tête change la langue de l'interface et sauvegarde le choix par personnage.
- Cliquez sur l'étoile d'un objet pour choisir sa priorité : `P3`, `P2`, `P1`, puis retrait. `P1` est la priorité maximale.
- Lorsqu'un objet de la wishlist apparaît dans la fenêtre de butin, dans un roll ou dans le chat de butin, une alerte visuelle et sonore est déclenchée.
- Un lien envoyé par le master looter, en avertissement raid ou par le chef de groupe/raid déclenche également l'alerte avant l'attribution.
- Maj-clic sur un objet insère son lien dans le chat.

## Commandes

- `/cw` : ouvrir ou fermer la fenêtre
- `/cw wishlist` : afficher toute la wishlist
- `/cw add <lien ou ID> [1-3]` : ajouter directement un objet
- `/cw remove <lien ou ID>` : retirer un objet
- `/cw auto` : activer/désactiver l'ouverture automatique
- `/cw filter` : activer/désactiver le filtre de classe
- `/cw stats` : activer/désactiver le filtre de caractéristiques
- `/cw sound` : activer/désactiver le son
- `/cw test` : tester le son
- `/cw refresh` : rescanner l'instance actuelle
- `/cw browse` : ouvrir le navigateur de butin
- `/cw search <nom ou ID>` : rechercher un objet

AtlasLoot et son module correspondant à l'extension de l'instance doivent être activés à l'écran des addons.

La wishlist est sauvegardée séparément pour chaque personnage et conserve le nom de l'instance et du boss source.

Le menu de l'addon permet de choisir entre le son personnalisé
`Media/sound_addon.ogg` et plusieurs sons intégrés au jeu. Le choix et l'état
activé/désactivé sont sauvegardés.

Le réglage `Délai entre sons` fixe l'intervalle minimum entre deux alertes sonores :
sans délai (par défaut), 1, 2, 3, 5, 10, 15, 30 ou 60 secondes. Les sons des alertes
reçues pendant cet intervalle sont ignorés, mais leurs alertes visuelles restent
affichées. Les aperçus et les tests de son restent immédiats. Ce réglage est
sauvegardé par personnage.
