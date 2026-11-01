--[[
	PlayerStateTests : tests automatiques de la logique d'équipe (à terre, réanimation, mort)
	et du calcul des vagues. Les joueurs sont simulés (faux joueurs), donc on peut tester
	le « multijoueur » sans lancer plusieurs clients.

	Lancer depuis la barre de commandes de Studio :
		require(game.ServerScriptService.Tests.PlayerStateTests)()
]]

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService:WaitForChild("Modules")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(Modules.PlayerState)
local ZombieRig = require(Modules.ZombieRig)
local WaveManager = require(Modules.WaveManager)

-- Faux joueur : même interface que Player pour ce que PlayerState utilise.
local function mockPlayer(name, position)
	local character = ZombieRig.build() -- on réutilise le rig comme personnage de test
	character.Name = name
	character:PivotTo(CFrame.new(position))
	character.Parent = Workspace

	local attributes = {}
	local player = { Name = name, UserId = math.random(1, 1e9), Character = character }
	function player:SetAttribute(key, value)
		attributes[key] = value
	end
	function player:GetAttribute(key)
		return attributes[key]
	end
	return player
end

return function()
	local passed, failed = 0, 0
	local report = {}

	local function check(name, condition)
		if condition then
			passed += 1
			table.insert(report, "PASS  " .. name)
		else
			failed += 1
			table.insert(report, "FAIL  " .. name)
		end
	end

	local function health(player)
		return player.Character:FindFirstChildOfClass("Humanoid").Health
	end

	local alice = mockPlayer("TestAlice", Vector3.new(0, 3, 0))
	local bob = mockPlayer("TestBob", Vector3.new(4, 3, 0))
	PlayerState.register(alice)
	PlayerState.spawned(alice, alice.Character)
	PlayerState.register(bob)
	PlayerState.spawned(bob, bob.Character)

	check("les deux joueurs démarrent en vie",
		PlayerState.getState(alice) == "Alive" and PlayerState.getState(bob) == "Alive")
	check("countAlive = 2", PlayerState.countAlive() == 2)

	-- 1. Dégâts non létaux
	PlayerState.damage(alice, 30)
	check("dégâts non létaux : reste en vie avec 70 PV",
		PlayerState.getState(alice) == "Alive" and health(alice) == 70)

	-- 2. Dégâts létaux -> à terre (et non mort)
	PlayerState.damage(alice, 500)
	check("dégâts létaux : le joueur est à terre", PlayerState.getState(alice) == "Down")
	check("à terre : 1 PV", health(alice) == 1)
	check("à terre : n'est plus compté comme en vie", PlayerState.countAlive() == 1)
	check("à terre : compté comme actif (difficulté)", PlayerState.countActive() == 2)

	-- 3. Un joueur à terre ne prend plus de dégâts et ne peut pas être achevé par erreur
	PlayerState.damage(alice, 50)
	check("à terre : les dégâts supplémentaires sont ignorés", health(alice) == 1)

	-- 4. Réanimation par un coéquipier proche (Bob est à 4 studs)
	local now = Workspace:GetServerTimeNow()
	for _ = 1, 20 do -- 20 x 0,2 s = 4 s > ReviveTime (3 s)
		PlayerState.step(0.2, now)
	end
	check("réanimation : le joueur est de nouveau en vie", PlayerState.getState(alice) == "Alive")
	check("réanimation : vie rendue = moitié de la vie max",
		health(alice) == Config.Player.MaxHealth * Config.Player.ReviveHealthFraction)

	-- 5. Coéquipier trop loin : pas de réanimation
	PlayerState.damage(alice, 500)
	bob.Character:PivotTo(CFrame.new(60, 3, 0))
	now = Workspace:GetServerTimeNow()
	for _ = 1, 20 do
		PlayerState.step(0.2, now)
	end
	check("coéquipier trop loin : reste à terre", PlayerState.getState(alice) == "Down")

	-- 6. Mort définitive quand le temps à terre est écoulé
	PlayerState.step(0.2, now + Config.Player.DownDuration + 1)
	check("temps écoulé : le joueur est mort", PlayerState.getState(alice) == "Dead")
	check("mort : PV à 0", health(alice) == 0)
	check("mort : seul Bob est encore en vie", PlayerState.countAlive() == 1)

	-- 7. Un joueur mort ne peut plus être relevé
	bob.Character:PivotTo(CFrame.new(1, 3, 0))
	for _ = 1, 20 do
		PlayerState.step(0.2, now)
	end
	check("mort : pas de réanimation possible", PlayerState.getState(alice) == "Dead")

	-- 8. Calcul des vagues
	check("vague 1 solo = 4 zombies", WaveManager.getZombieCount(1, 1) == 4)
	check("les vagues grossissent", WaveManager.getZombieCount(6, 1) > WaveManager.getZombieCount(5, 1))
	check("4 joueurs > 1 joueur (même vague)", WaveManager.getZombieCount(5, 4) > WaveManager.getZombieCount(5, 1))
	check("jamais zéro zombie, même avec 0 joueur", WaveManager.getZombieCount(1, 0) >= 1)

	-- Nettoyage
	PlayerState.unregister(alice)
	PlayerState.unregister(bob)
	alice.Character:Destroy()
	bob.Character:Destroy()

	table.insert(report, string.format("\n%d réussis, %d échoués", passed, failed))
	local text = table.concat(report, "\n")
	print(text)
	return text
end
