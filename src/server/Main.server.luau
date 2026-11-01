--[[
	Main : point d'entrée serveur. Ne contient aucune logique de jeu,
	elle ne fait que démarrer les modules dans le bon ordre.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = script.Parent:WaitForChild("Modules")
local MapBuilder = require(Modules.MapBuilder)
local PlayerState = require(Modules.PlayerState)
local ZombieService = require(Modules.ZombieService)
local WeaponService = require(Modules.WeaponService)
local WaveManager = require(Modules.WaveManager)
local GameManager = require(Modules.GameManager)

-- Les personnages sont créés par GameManager (pas d'apparition automatique) :
-- c'est ce qui permet qu'un joueur mort ne réapparaisse pas.
Players.CharacterAutoLoads = false

-- Seul canal réseau client -> serveur de la V0 : « je tire vers ce point »
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local fireWeapon = Instance.new("RemoteEvent")
fireWeapon.Name = "FireWeapon"
fireWeapon.Parent = remotes

MapBuilder.build()
ZombieService.start()
PlayerState.start()
WeaponService.start(fireWeapon)
WaveManager.init()

-- Créditer les kills au joueur qui a achevé le zombie
ZombieService.onKilled(function(attacker)
	if attacker and attacker.Parent then
		attacker:SetAttribute("Kills", (attacker:GetAttribute("Kills") or 0) + 1)
	end
end)

GameManager.init()
