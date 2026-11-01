# Architecture

## Le principe
Dans Roblox, un joueur peut modifier son propre client pour tricher, mais pas le serveur. Donc tout ce qui compte (dégâts, vie, vagues, zombies, défaite) est calculé sur le serveur. Le client envoie juste ce que veut faire le joueur (« je tire vers ce point ») et affiche ce que le serveur lui renvoie. Comme il n'y a qu'une seule version de la partie, tous les joueurs voient les mêmes zombies et la même vague

```
Client                                 Serveur
WeaponClient --FireWeapon(point)-->    WeaponService (vérifie le tir, fait les dégâts)
HUD <-- attributs répliqués --------   PlayerState / WaveManager / GameManager
```

## Les modules

| Module | Rôle |
|---|---|
| `Config` | Toutes les valeurs de réglage (dégâts, durées, nombre de zombies) |
| `PlayerState` | État d'un joueur : en vie, à terre, mort |
| `ZombieService` / `ZombieRig` | Les zombies et leur IA, modèle généré par code |
| `WeaponService` | L'arme et la vérification des tirs |
| `WaveManager` | Les vagues et la difficulté |
| `GameManager` | Début de partie, défaite, nouvelle partie |
| `MapBuilder` | Le décor |
| `Main` | Démarre tout dans l'ordre |

Chaque système prévu plus tard (inventaire, économie, base) sera un module de plus, sans avoir à tout réécrire

## Mes choix

- **Un seul fichier de réglages.** Pour équilibrer le jeu en avril, je n'aurai pas à fouiller dans le code
- **Le joueur tombe avant de mourir.** À 0 PV il est « à terre » 25 secondes, et un coéquipier à moins de 8 mètres peut le relever en 3 secondes. Ça rend le coop utile. L'état est partagé via des attributs du joueur, que Roblox copie tout seul chez tout le monde
- **Défaite quand plus personne n'est debout.** Si tout le monde est à terre, personne ne peut relever personne
- **Pas de réapparition automatique.** Sinon Roblox ferait revenir un joueur mort, même s'il se reconnecte. Je garde son identifiant pour la durée de la partie
- **Tirs vérifiés par le serveur.** Il contrôle que le joueur est debout, qu'il a son arme et que la cadence est respectée, puis il fait lui-même le calcul du tir. Je referai pareil pour les achats
- **Une seule boucle pour tous les zombies**, toutes les 0,2 s, plutôt qu'un script par zombie. Ils appartiennent au serveur, donc tout le monde les voit au même endroit
- **25 zombies maximum à la fois**, pour garder le jeu fluide
- **Un « jeton » pour arrêter les vagues.** Quand l'équipe est éliminée, la boucle des vagues s'arrête proprement et ne fait pas apparaître de zombies dans la partie suivante
- **Décor et zombies faits par code.** Pas d'assets à créer, et le dépôt reste du texte lisible.(voir [PLANNING.md](PLANNING.md))
- **Rojo.** Le code est dans des fichiers `.luau` suivis par Git, pas enfermé dans le fichier Studio

## Limites de la V0
- Les zombies foncent tout droit, sans chercher leur chemin
- Le record de vagues n'est gardé que tant que le serveur tourne
- Un seul zombie, une seule arme, pas d'inventaire ni d'économie
- Pas de sons ni d'animations
