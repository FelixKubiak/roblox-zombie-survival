--[[
	GameManager : cycle de vie d'une partie (début, défaite d'équipe, nouvelle partie).

	Règles (cahier des charges, sections 6 et 15) :
	  - la partie est perdue uniquement quand plus aucun joueur n'est EN VIE
	    (si tous les survivants sont à terre, personne ne peut les relever :
	    c'est donc la défaite) ;
	  - à la fin, tout repart de zéro (nouvelle partie après l'écran de résultat) ;
	  - un joueur mort ou parti à terre ne peut pas revenir en jeu avant la fin
	    de la partie : il ne réapparaît pas, même s'il se reconnecte ;
	  - la partie continue tant qu'au moins un joueur est en vie ;
	  - plus de 4 joueurs : les suivants sont refusés.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local ZombieService = require(script.Parent.ZombieService)
local WeaponService = require(script.Parent.WeaponService)
local WaveManager = require(script.Parent.WaveManager)

local GameManager = {}

local running = false
local generation = 0 -- invalide les redémarrages programmés devenus obsolètes
local deadThisRun = {} -- [UserId] = true : ne peut pas réapparaître avant la prochaine partie
local bestWaves = 0 -- record de la session serveur (le classement global viendra avec les DataStores)

local function spawnPlayer(player)
	if deadThisRun[player.UserId] then
		return -- reste mort (spectateur) jusqu'à la prochaine partie
	end
	local ok, err = pcall(function()
		player:LoadCharacter()
	end)
	if not ok then
		warn("[GameManager] LoadCharacter a échoué : " .. tostring(err))
		return
	end
	if player.Character then
		PlayerState.spawned(player, player.Character)
		WeaponService.give(player)
	end
end

function GameManager.beginRun(respawnAll)
	generation += 1
	WaveManager.stop()
	ZombieService.clearAll()
	deadThisRun = {}
	running = true

	for _, player in Players:GetPlayers() do
		player:SetAttribute("Kills", 0)
		if respawnAll then
			task.spawn(spawnPlayer, player)
		end
	end
	WaveManager.start()
end

function GameManager.toLobby()
	generation += 1
	running = false
	WaveManager.stop()
	ZombieService.clearAll()
	deadThisRun = {}
	ReplicatedStorage:SetAttribute("Wave", 0)
	ReplicatedStorage:SetAttribute("ZombiesLeft", 0)
	WaveManager.setPhase("Lobby", nil)
end

function GameManager.endRun()
	if not running then
		return
	end
	running = false
	WaveManager.stop()

	local cleared = ReplicatedStorage:GetAttribute("WavesCleared") or 0
	bestWaves = math.max(bestWaves, cleared)
	ReplicatedStorage:SetAttribute("BestWaves", bestWaves)
	WaveManager.setPhase("GameOver", Config.GameOver.ResultDuration)

	generation += 1
	local myGeneration = generation
	task.delay(Config.GameOver.ResultDuration, function()
		if myGeneration ~= generation then
			return
		end
		if #Players:GetPlayers() == 0 then
			GameManager.toLobby()
		else
			GameManager.beginRun(true)
		end
	end)
end

local function checkDefeat()
	if running and PlayerState.countAlive() == 0 then
		GameManager.endRun()
	end
end

local function onPlayerAdded(player)
	if #Players:GetPlayers() > Config.Team.MaxPlayers then
		player:Kick("La partie est complète (" .. Config.Team.MaxPlayers .. " joueurs maximum).")
		return
	end
	player:SetAttribute("Kills", 0)
	PlayerState.register(player)
	task.spawn(spawnPlayer, player)

	if ReplicatedStorage:GetAttribute("Phase") == "Lobby" then
		GameManager.beginRun(false)
	end
end

local function onPlayerRemoving(player)
	local state = PlayerState.getState(player)
	if running and state == PlayerState.DOWN then
		deadThisRun[player.UserId] = true -- partir à terre ne permet pas d'échapper à la mort
	end
	PlayerState.unregister(player)
	WeaponService.forget(player)

	task.defer(function()
		if #Players:GetPlayers() == 0 then
			GameManager.toLobby()
		else
			checkDefeat()
		end
	end)
end

function GameManager.init()
	WaveManager.setPhase("Lobby", nil)

	PlayerState.onChanged(function(player, newState)
		if newState == PlayerState.DEAD then
			deadThisRun[player.UserId] = true
		end
		if newState ~= PlayerState.ALIVE then
			checkDefeat()
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return GameManager
