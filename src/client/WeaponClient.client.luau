--[[
	WeaponClient : transforme le clic de la souris en demande de tir.
	Le client n'envoie que la position visée ; c'est le serveur qui décide
	si le tir est valide et quels dégâts sont infligés (voir WeaponService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local fireRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FireWeapon")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local firing = false

local function hasWeaponEquipped()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool.Name == Config.Weapon.Name
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 or firing then
		return
	end

	firing = true
	-- Tir continu tant que le bouton est maintenu
	while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		and hasWeaponEquipped()
		and player:GetAttribute("State") == "Alive"
	do
		fireRemote:FireServer(mouse.Hit.Position)
		task.wait(Config.Weapon.Cooldown)
	end
	firing = false
end)
