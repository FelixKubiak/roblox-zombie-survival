--[[
	MapBuilder : construit le décor de la V0 entièrement par code (sol, arbres,
	rochers, caisses, lampadaires, feu de camp, ambiance nocturne).

	Avantages : dépôt Git 100 % texte, décor reproductible (graine fixe)
	et aucun asset à créer à la main pendant la phase prototype.
	La vraie carte (forêt, bases, grottes...) viendra plus tard.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local MapBuilder = {}

local function addPart(parent, props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	part.Parent = parent
	return part
end

local function randomOffset(rng, minRadius, maxRadius)
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(minRadius, maxRadius)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function addTree(parent, rng, position)
	local height = rng:NextNumber(14, 22)
	local leaf = rng:NextNumber(12, 18)
	addPart(parent, {
		Name = "Trunk",
		Size = Vector3.new(2.2, height, 2.2),
		Position = position + Vector3.new(0, height / 2, 0),
		Color = Color3.fromRGB(84, 58, 38),
		Material = Enum.Material.Wood,
	})
	addPart(parent, {
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(leaf, leaf, leaf),
		Position = position + Vector3.new(0, height + leaf * 0.2, 0),
		Color = Color3.fromRGB(30, 70, 38),
		Material = Enum.Material.Grass,
	})
end

local function addLampPost(parent, position)
	addPart(parent, {
		Name = "LampPost",
		Size = Vector3.new(0.7, 11, 0.7),
		Position = position + Vector3.new(0, 5.5, 0),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
	})
	local bulb = addPart(parent, {
		Name = "LampBulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.8, 1.8, 1.8),
		Position = position + Vector3.new(0, 11.5, 0),
		Color = Color3.fromRGB(255, 226, 150),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Range = 42
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 214, 140)
	light.Parent = bulb
end

local function addCampfire(parent, position)
	for _, angle in { 20, 110 } do
		addPart(parent, {
			Name = "Log",
			Size = Vector3.new(0.9, 0.9, 5),
			CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, math.rad(angle), 0),
			Color = Color3.fromRGB(70, 46, 28),
			Material = Enum.Material.Wood,
		})
	end
	local flame = addPart(parent, {
		Name = "FirePoint",
		Size = Vector3.new(1, 1, 1),
		Position = position + Vector3.new(0, 1.2, 0),
		Transparency = 1,
		CanCollide = false,
	})
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 8
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 2.5
	light.Color = Color3.fromRGB(255, 150, 70)
	light.Parent = flame
end

function MapBuilder.build()
	local rng = Random.new(2026)
	local center = Config.Map.Center
	local groundY = Config.Map.GroundY

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	-- Sol : on réutilise la Baseplate si elle existe, sinon on en crée une.
	local ground = Workspace:FindFirstChild("Baseplate")
	if ground and ground:IsA("BasePart") then
		local texture = ground:FindFirstChildOfClass("Texture")
		if texture then
			texture:Destroy()
		end
	else
		ground = addPart(Workspace, {
			Name = "Baseplate",
			Size = Vector3.new(1024, 2, 1024),
			Position = Vector3.new(0, groundY - 1, 0),
			Locked = true,
		})
	end
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(48, 72, 46)

	-- Point d'apparition des joueurs
	if not Workspace:FindFirstChildOfClass("SpawnLocation") then
		local spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Position = center + Vector3.new(0, groundY + 0.5, 0)
		spawn.Parent = Workspace
	end

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = map

	-- Arbres : en dehors du cercle d'apparition des zombies (ils ne gênent pas l'IA)
	local ringStart = Config.Waves.SpawnRadius + 15
	for _ = 1, 45 do
		addTree(decor, rng, center + randomOffset(rng, ringStart, ringStart + 70) + Vector3.new(0, groundY, 0))
	end

	-- Rochers et caisses : petits obstacles dans la zone de combat
	for _ = 1, 10 do
		local size = rng:NextNumber(3, 5)
		addPart(decor, {
			Name = "Rock",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = center + randomOffset(rng, 22, 60) + Vector3.new(0, groundY + size * 0.3, 0),
			Color = Color3.fromRGB(95, 98, 104),
			Material = Enum.Material.Slate,
		})
	end
	for _ = 1, 8 do
		addPart(decor, {
			Name = "Crate",
			Size = Vector3.new(3, 3, 3),
			CFrame = CFrame.new(center + randomOffset(rng, 15, 45) + Vector3.new(0, groundY + 1.5, 0))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			Color = Color3.fromRGB(150, 108, 62),
			Material = Enum.Material.Wood,
		})
	end

	-- Lampadaires autour du point d'apparition + feu de camp
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		addLampPost(decor, center + Vector3.new(math.cos(angle) * 20, groundY, math.sin(angle) * 20))
	end
	addCampfire(decor, center + Vector3.new(8, groundY, 8))

	-- Ambiance nocturne
	Lighting.ClockTime = 20.8
	Lighting.Brightness = 1.2
	Lighting.Ambient = Color3.fromRGB(50, 55, 75)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 75, 100)
	Lighting.FogColor = Color3.fromRGB(25, 28, 40)
	Lighting.FogStart = 90
	Lighting.FogEnd = 480
end

return MapBuilder
