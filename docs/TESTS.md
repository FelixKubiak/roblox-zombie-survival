# Tests

Je teste les systèmes importants (vagues, mort d'équipe, multijoueur) au fur et à mesure, pas à la fin du projet

## 1. Tests automatiques

Fichier : `src/server/Tests/PlayerStateTests.luau`. Pour les lancer, dans la barre de commandes de Studio (mode édition) :

```lua
require(game.ServerScriptService.Tests.PlayerStateTests)()
```

Le test utilise de faux joueurs et un temps simulé (`PlayerState.step(dt, now)`). 
On peut donc tester la logique d'équipe sans lancer plusieurs clients et sans attendre 25 secondes

| Cas testé | Résultat attendu |
|---|---|
| Deux joueurs démarrent | Les deux sont en vie |
| Dégâts non létaux (30) | Reste en vie avec 70 PV |
| Dégâts létaux (500) | À terre avec 1 PV, pas mort |
| Joueur à terre | Plus « en vie », mais toujours « actif » |
| Dégâts supplémentaires à terre | Ignorés |
| Coéquipier à 4 studs pendant 4 s | Joueur relevé avec 50 PV |
| Coéquipier à 60 studs | Reste à terre |
| 25 s sans aide | Mort (0 PV) |
| Joueur mort + coéquipier à côté | Pas de réanimation |
| Vague 1 en solo | 4 zombies |
| Vague 6 contre vague 5 | Plus de zombies |
| Même vague à 4 joueurs contre 1 | Plus de zombies |
| 0 joueur | Jamais zéro zombie |

Dernier résultat : **19 réussis, 0 échoué.**

## 2. Tests en jeu (solo)

Faits dans Studio avec une vraie partie :

- Le joueur reçoit le pistolet et les zombies viennent vers lui
- Un tir valide fait des dégâts et le kill est compté au bon joueur
- Quand la vague est finie, la pause démarre puis la vague suivante
- Mort du joueur : écran de défaite, puis nouvelle partie (vague 1, kills à zéro, arme redonnée)
- Un joueur à terre ne peut plus tirer, le serveur refuse le tir

## 3. Tests multijoueur

Tests faits dans Studio avec 1 serveur et 2 à 5 clients (*Test → Serveur et clients*, puis *Ajouter des clients*) :

- [x] Les deux clients voient la même vague, le même nombre de zombies et le même état des joueurs
- [x] Joueur à terre avec un coéquipier proche : relevé en 2,9 s, avec 50 PV
- [x] Joueur à terre sans aide : mort après 25,3 s, il ne revient pas, la partie continue pour l'autre
- [x] Dernier joueur debout à terre : défaite chez tous (0,1 s après), puis nouvelle partie propre (100 PV, pistolet, 0 kill)
- [x] Un joueur quitte en cours de partie : l'autre continue normalement
- [ ] Un joueur quitte à terre puis revient : il ne doit pas réapparaître avant la fin de la partie (code relu, mais pas testable seul dans Studio : chaque client ajouté reçoit un nouveau compte, à tester avec un ami)
- [x] Parties à 3 et 4 joueurs (12 novembre) : tous en vie au départ, état de l'équipe visible dans l'interface, 9 zombies à la vague 1 avec 3 joueurs et 11 avec 4 (4 en solo), défaite d'équipe puis nouvelle partie avec les 4 joueurs
- [x] Un 5ᵉ joueur est refusé (12 novembre) : il est ajouté puis retiré aussitôt, les 4 autres restent en vie et la partie continue
- [ ] Test avec des joueurs distants (latence réelle)

## 4. Prochaines étapes

- Tester `GameManager` (défaite, reconnexion) avec de faux joueurs
- Test de charge : 25 zombies actifs et mesure de la fréquence d'images
- Un fichier de tests par nouveau module (inventaire, économie, base)
