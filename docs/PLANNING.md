# Planning, répartition du temps et suivi

## Répartition du temps : code d'abord, assets ensuite

Le projet est un projet de **licence informatique** : la priorité est la programmation (IA, réseau, synchronisation, économie, architecture). Les modèles, sons et animations sont nécessaires pour un jeu fini, mais ne doivent pas grignoter le temps de gameplay.

Répartition visée sur l'année :

| Activité | Part du temps visée |
|---|---|
| Programmation des systèmes (vagues, IA, réseau, économie, base, classes) | ~70 % |
| Tests, documentation, rapports | ~15 % |
| Création / intégration d'assets (modèles, sons, animations) | ~15 % |

### Principe : générer ou récupérer plutôt que créer à la main

| Type d'asset | Stratégie |
|---|---|
| Personnages / zombies | Modèles R6 générés par code (déjà fait pour la V0) ; variantes par couleur, taille et accessoires simples |
| Décor | Pièces Roblox assemblées par code ; vraie carte construite avec des éléments simples (blocs, terrain Roblox) |
| Sons | Sons libres de droits de la bibliothèque Roblox (Creator Store), ou sons simples du commerce libres de droits |
| Animations | Animations par défaut de Roblox ; quelques mouvements par code avec `TweenService` |
| Interface | Construite par code (déjà fait pour le HUD de la V0) |
| Boss, armes | Assemblage de pièces simples + effets (particules, couleurs) pour les distinguer |

Les assets « créés pour le projet » du cahier des charges sont donc remplacés par des assets **générés par code ou assemblés à partir de ressources libres**, et créés à la main seulement si le temps le permet (mars). Ce choix est détaillé dans [ARCHITECTURE.md](ARCHITECTURE.md).

## Journal de bord

Je n'ai pas noté mes heures au jour le jour au début. Ce journal est donc **reconstitué** : les jours sont ceux où je travaille sur le projet (mercredi, jeudi, vendredi, depuis le 9 octobre) et les durées sont des **estimations** (environ 4 h par jour). À partir de novembre, je note le temps réel à chaque séance.

| Date | Travail | Temps (estimé) |
|---|---|---|
| Ven 09/10 | Relecture du cahier des charges, choix de ce que doit faire la V0 (un personnage, une arme, des vagues, du multi de base), début du suivi du temps | 3 h |
| Mer 14/10 | Prise en main de Roblox Studio et de Luau : scripts serveur et client, notions de client / serveur, premiers essais | 4 h |
| Jeu 15/10 | Conception de l'architecture : le serveur décide, le client affiche ; découpage en modules ; choix de générer décor et zombies par code | 4 h |
| Ven 16/10 | Préparation du projet : dossier `src/`, fichier de réglages `Config`, premiers essais de décor | 4 h |
| Mer 21/10 | Réflexion sur la coopération : états du joueur (en vie, à terre, mort), réanimation, règle de défaite d'équipe | 4 h |
| Jeu 22/10 | Zombies : modèle fait par code, poursuite du joueur le plus proche, attaque | 4 h |
| Ven 23/10 | Pistolet : le client envoie le point visé, le serveur vérifie le tir et applique les dégâts | 4 h |
| Mer 28/10 | Installation des outils : Rojo (synchronisation avec Studio), Git et dépôt GitHub, `.gitignore` | 4 h |
| Jeu 29/10 | Mise en place du code dans le dépôt : états du joueur, zombies, pistolet, vagues, boucle de partie, interface, 19 tests automatiques, README et documentation | 4 h |
| Ven 30/10 | Test multijoueur à 2 clients, nouvelles captures d'écran, rédaction du rapport n°1 | 4 h |

Total estimé : 10 jours, environ 40 h.
