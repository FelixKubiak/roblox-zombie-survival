# Roblox Zombie Survival

Jeu de survie coopérative sur Roblox (1 à 4 joueurs) : l'équipe affronte des vagues de zombies sans limite prédéfinie, jusqu'à la mort de tous les joueurs

Projet personnel — **Roblox Studio** + **Luau**, synchronisé avec **Rojo**.

> **État actuel : prototype V0 (octobre 2026).** Un personnage, un pistolet, des vagues de zombies, un décor généré par code, le multijoueur de base (à terre / réanimation / défaite d'équipe) et des tests automatiques. voir [docs/PLANNING.md](docs/PLANNING.md)

## Ce que fait la V0

- **Un joueur, une arme** : pistolet. Les tirs sont validés par le serveur.
- **Vagues de zombies** sans fin : plus de zombies, plus de vie et plus de vitesse à chaque vague, et plus de zombies quand l'équipe est plus grande.
- **Multijoueur (1 à 4)** : tous les joueurs voient les mêmes zombies et la même vague.
  - À 0 PV, un joueur est **à terre** : un coéquipier proche peut le relever, sinon il meurt au bout de 25 s.
  - Un joueur mort ne réapparaît pas avant la fin de la partie (même s'il se reconnecte).
  - **Défaite d'équipe** quand plus personne n'est en vie, puis nouvelle partie de zéro.
- **Interface** : vie, vague, zombies restants, état de l'équipe, écran « à terre » et écran de défaite.
- **Décor** : sol, arbres, rochers, caisses, lampadaires, feu de camp, ambiance nocturne — le tout généré par code.

## Lancer le jeu

Prérequis : [Roblox Studio](https://create.roblox.com/) et [Rojo](https://rojo.space/). 
Ouvrir le dossier dans VS Code, accepter l'extension recommandée **Rojo**, puis menu *Rojo → Install Rojo now* et *Install Roblox Studio Plugin*.

1. Cloner le dépôt :
   ```
   git clone https://github.com/FelixKubiak/roblox-zombie-survival.git
   cd roblox-zombie-survival
   ```
2. Dans Roblox Studio, créer un nouveau lieu **Baseplate**.
3. Lancer le serveur Rojo (menu Rojo de VS Code → `default.project.json`, ou `rojo serve` en ligne de commande), puis dans Studio : *Plugins → Rojo → Connect*.
4. Appuyer sur **F5** (Test → Jouer). Pour tester à plusieurs : *Test → Clients and Servers*, choisir 2 à 4 joueurs.

Contrôles : **ZQSD / flèches** pour se déplacer, **clic gauche** pour tirer (maintenir pour tir continu).

Le décor n'apparaît qu'en jeu (F5), pas dans l'éditeur : il est créé par `MapBuilder` au lancement.

## Structure du dépôt

```
default.project.json            Rojo : dossiers -> services Roblox
src/
  shared/Config.luau            Toutes les valeurs d'équilibrage (ReplicatedStorage)
  server/                       ServerScriptService
    Main.server.luau            Point d'entrée : démarre les modules
    Modules/
      GameManager.luau          Cycle de partie : défaite d'équipe, nouvelle partie
      WaveManager.luau          Enchaînement des vagues
      ZombieService.luau        Création et IA des zombies
      ZombieRig.luau            Modèle de zombie généré par code
      WeaponService.luau        Arme + validation des tirs
      PlayerState.luau          Vivant / à terre / mort, réanimation
      MapBuilder.luau           Décor généré par code
    Tests/
      PlayerStateTests.luau     Tests automatiques
  client/                       StarterPlayerScripts
    WeaponClient.client.luau    Clic souris -> demande de tir
    HUD.client.luau             Interface (lecture seule de l'état serveur)
docs/
  ARCHITECTURE.md               Choix d'architecture et leurs raisons
  TESTS.md                      Stratégie et plan de tests
  PLANNING.md                   Planning, répartition code / assets, temps passé
```

## Documentation

- [Architecture et choix techniques](docs/ARCHITECTURE.md)
- [Tests](docs/TESTS.md)
- [Planning, temps passé et écarts](docs/PLANNING.md)

## Tests

Dans la barre de commandes de Roblox Studio :

```lua
require(game.ServerScriptService.Tests.PlayerStateTests)()
```



