--[[
	WeaponService : arme du joueur, avec validation côté serveur.

	Le client envoie seulement « je vise ce point ». Le serveur vérifie tout :
	le joueur est vivant, l'arme est équipée, la cadence est respectée,
	puis il fait lui-même le raycast et applique les dégâts.
	Un client modifié ne peut donc ni tirer plus vite, ni infliger plus de dégâts.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local ZombieService = require(script.Parent.ZombieService)

local WeaponService = {}

local lastShot = {} -- [player] = os.clock() du dernier tir accepté
local effectsFolder

function WeaponService.give(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = Config.Weapon.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Clic gauche pour tirer"
	tool.Grip = CFrame.new(0, -0.2, 0.5)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.6, 1.5)
	handle.Color = Color3.fromRGB(35, 35, 40)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool

	tool.Parent = player:FindFirstChildOfClass("Backpack")
	humanoid:EquipTool(tool)
end

local function drawTracer(from, to)
	local length = (to - from).Magnitude
	local tracer = Instance.new("Part")
	tracer.Name = "Tracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 220, 120)
	tracer.Size = Vector3.new(0.12, 0.12, length)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = effectsFolder
	Debris:AddItem(tracer, 0.06)
end

-- Traite une demande de tir. Retourne true si le tir a été accepté,
-- sinon false et la raison du refus (utile pour les tests et le débogage).
function WeaponService.fire(player, aimPoint)
	-- 1. Valider ce que le client a envoyé (jamais lui faire confiance)
	if typeof(aimPoint) ~= "Vector3" or not (aimPoint.Magnitude < 1e6) then
		return false, "argument"
	end

	-- 2. Valider l'état du joueur
	if PlayerState.getState(player) ~= PlayerState.ALIVE then
		return false, "etat=" .. tostring(PlayerState.getState(player))
	end
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local head = character and character:FindFirstChild("Head")
	if not tool or tool.Name ~= Config.Weapon.Name or not head then
		return false, "outil/tete"
	end

	-- 3. Cadence de tir (légère tolérance pour la latence réseau)
	local now = os.clock()
	local last = lastShot[player]
	if last and now - last < Config.Weapon.Cooldown * 0.9 then
		return false, "cadence"
	end
	lastShot[player] = now

	-- 4. Raycast côté serveur ; les coéquipiers ne bloquent pas les balles
	local origin = head.Position
	local offset = aimPoint - origin
	if offset.Magnitude < 0.5 then
		return false, "trop proche"
	end
	local direction = offset.Unit * Config.Weapon.Range

	local ignore = {}
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	local result = Workspace:Raycast(origin, direction, params)
	local endPoint = result and result.Position or (origin + direction)

	local handle = tool:FindFirstChild("Handle")
	drawTracer(handle and handle.Position or origin, endPoint)

	-- 5. Dégâts
	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if model and ZombieService.isZombie(model) then
			local multiplier = result.Instance.Name == "Head" and Config.Weapon.HeadshotMultiplier or 1
			ZombieService.damage(model, Config.Weapon.Damage * multiplier, player)
		end
	end
	return true
end

function WeaponService.forget(player)
	lastShot[player] = nil
end

function WeaponService.start(fireRemote)
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = Workspace

	fireRemote.OnServerEvent:Connect(function(player, aimPoint)
		WeaponService.fire(player, aimPoint)
	end)
end

return WeaponService
