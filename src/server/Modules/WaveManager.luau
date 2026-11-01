--[[
	WaveManager : enchaîne les vagues sans limite prédéfinie.

	L'état est publié en attributs sur ReplicatedStorage (lus par l'interface) :
	  Phase        "Lobby" | "Intermission" | "Wave" | "GameOver"
	  Wave         numéro de la vague en cours
	  WavesCleared nombre de vagues terminées (= « vagues survécues »)
	  ZombiesLeft  zombies restant à tuer dans la vague
	  PhaseEndsAt  heure serveur de fin de la phase (pour les comptes à rebours)

	Un « jeton » (token) permet d'arrêter proprement une boucle de vagues
	quand l'équipe est éliminée, sans threads orphelins.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local ZombieService = require(script.Parent.ZombieService)

local WaveManager = {}

local token = 0
local waveTotal = 0
local waveKilled = 0

-- Nombre de zombies d'une vague, adapté à la taille de l'équipe.
function WaveManager.getZombieCount(wave, playerCount)
	local w = Config.Waves
	local base = w.BaseCount + w.CountPerWave * (wave - 1)
	local scale = 1 + w.TeamScaling * (math.max(playerCount, 1) - 1)
	return math.floor(base * scale + 0.5)
end

local function setPhase(phase, duration)
	ReplicatedStorage:SetAttribute("Phase", phase)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", duration and (Workspace:GetServerTimeNow() + duration) or 0)
end

function WaveManager.setPhase(phase, duration)
	setPhase(phase, duration)
end

local function randomSpawnPoint()
	local angle = math.random() * math.pi * 2
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.Waves.SpawnRadius
	return Config.Map.Center + offset + Vector3.new(0, Config.Map.GroundY + 4, 0)
end

-- Attend `seconds` ; retourne false si la partie a été interrompue entre-temps.
local function waitFor(myToken, seconds)
	local untilTime = os.clock() + seconds
	while os.clock() < untilTime do
		if myToken ~= token then
			return false
		end
		task.wait(0.1)
	end
	return myToken == token
end

local function runLoop(myToken)
	ReplicatedStorage:SetAttribute("Wave", 0)
	ReplicatedStorage:SetAttribute("WavesCleared", 0)
	ReplicatedStorage:SetAttribute("ZombiesLeft", 0)
	setPhase("Intermission", Config.Waves.FirstWaveDelay)
	if not waitFor(myToken, Config.Waves.FirstWaveDelay) then
		return
	end

	local wave = 0
	while myToken == token do
		wave += 1
		waveTotal = WaveManager.getZombieCount(wave, PlayerState.countActive())
		waveKilled = 0
		ReplicatedStorage:SetAttribute("Wave", wave)
		ReplicatedStorage:SetAttribute("ZombiesLeft", waveTotal)
		setPhase("Wave", 0)

		-- Apparition progressive, avec un plafond de zombies simultanés
		local spawned = 0
		while spawned < waveTotal and myToken == token do
			if ZombieService.getAliveCount() < Config.Waves.MaxAlive then
				ZombieService.spawn(wave, randomSpawnPoint())
				spawned += 1
				task.wait(Config.Waves.SpawnInterval)
			else
				task.wait(0.25)
			end
		end

		-- Attente de la fin de la vague
		while myToken == token and waveKilled < waveTotal do
			task.wait(0.2)
		end
		if myToken ~= token then
			return
		end

		ReplicatedStorage:SetAttribute("WavesCleared", wave)
		setPhase("Intermission", Config.Waves.Intermission)
		if not waitFor(myToken, Config.Waves.Intermission) then
			return
		end
	end
end

function WaveManager.start()
	token += 1
	local myToken = token
	task.spawn(runLoop, myToken)
end

function WaveManager.stop()
	token += 1
end

-- À appeler une fois au démarrage du serveur.
function WaveManager.init()
	ZombieService.onKilled(function()
		waveKilled += 1
		ReplicatedStorage:SetAttribute("ZombiesLeft", math.max(0, waveTotal - waveKilled))
	end)
end

return WaveManager
