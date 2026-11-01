--[[
	ZombieService : création et IA des zombies.

	Une seule boucle d'IA pour tous les zombies (plutôt qu'un thread par zombie) :
	à chaque tick, chaque zombie vise le joueur vivant le plus proche,
	se déplace vers lui et attaque à portée.
	Les zombies appartiennent au serveur (SetNetworkOwner(nil)) : pas de triche possible
	et tous les joueurs voient les mêmes ennemis.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local ZombieRig = require(script.Parent.ZombieRig)

local ZombieService = {}

local zombies = {} -- [model] = record
local aliveCount = 0
local killedListeners = {}
local folder

-- callback(attacker: Player?) appelé à chaque zombie mort
function ZombieService.onKilled(callback)
	table.insert(killedListeners, callback)
end

function ZombieService.getStats(wave)
	local z = Config.Zombie
	return {
		health = z.BaseHealth + z.HealthPerWave * (wave - 1),
		speed = math.min(z.MaxSpeed, z.BaseSpeed + z.SpeedPerWave * (wave - 1)),
	}
end

function ZombieService.getAliveCount()
	return aliveCount
end

function ZombieService.isZombie(model)
	return zombies[model] ~= nil
end

local function finish(model, record)
	if zombies[model] ~= record then
		return
	end
	zombies[model] = nil
	aliveCount -= 1
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanQuery = false -- le cadavre ne bloque plus les tirs
		end
	end
	Debris:AddItem(model, 4)
	for _, callback in killedListeners do
		task.spawn(callback, record.attacker)
	end
end

function ZombieService.spawn(wave, position)
	local model = ZombieRig.build()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	local stats = ZombieService.getStats(wave)

	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.WalkSpeed = stats.speed

	model:PivotTo(CFrame.new(position))
	model.Parent = folder or Workspace
	root:SetNetworkOwner(nil)

	local record = {
		model = model,
		humanoid = humanoid,
		root = root,
		nextAttack = 0,
		lastPosition = position,
		attacker = nil,
	}
	zombies[model] = record
	aliveCount += 1

	humanoid.Died:Connect(function()
		finish(model, record)
	end)
	return model
end

-- Inflige des dégâts à un zombie ; `attacker` sert à créditer le kill.
function ZombieService.damage(model, amount, attacker)
	local record = zombies[model]
	if not record or record.humanoid.Health <= 0 then
		return false
	end
	record.attacker = attacker
	record.humanoid:TakeDamage(amount)
	return true
end

-- Supprime tous les zombies (fin de partie) sans les compter comme des kills.
function ZombieService.clearAll()
	for model in zombies do
		model:Destroy()
	end
	zombies = {}
	aliveCount = 0
end

local function nearestTarget(position, targets)
	local best, bestDistance = nil, math.huge
	for _, target in targets do
		local distance = (target.root.Position - position).Magnitude
		if distance < bestDistance then
			best, bestDistance = target, distance
		end
	end
	return best, bestDistance
end

local function aiStep()
	local targets = PlayerState.getAliveTargets()
	local now = os.clock()

	for model, record in zombies do
		local humanoid, root = record.humanoid, record.root

		-- Modèle détruit ou tombé hors de la carte : on le compte comme mort.
		if not model.Parent or not root.Parent then
			finish(model, record)
			continue
		end
		if root.Position.Y < -50 then
			humanoid.Health = 0
			continue
		end

		local target, distance = nearestTarget(root.Position, targets)
		if not target then
			continue
		end

		if distance <= Config.Zombie.AttackRange then
			humanoid:MoveTo(root.Position)
			local targetPosition = target.root.Position
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z))
			if now >= record.nextAttack then
				record.nextAttack = now + Config.Zombie.AttackCooldown
				PlayerState.damage(target.player, Config.Zombie.Damage)
			end
		else
			humanoid:MoveTo(target.root.Position)
			-- Anti-blocage simple : s'il n'avance plus, il saute (pathfinding prévu plus tard).
			local moved = (root.Position - record.lastPosition) * Vector3.new(1, 0, 1)
			if moved.Magnitude < 0.3 then
				humanoid.Jump = true
			end
			record.lastPosition = root.Position
		end
	end
end

function ZombieService.start()
	folder = Instance.new("Folder")
	folder.Name = "Zombies"
	folder.Parent = Workspace

	task.spawn(function()
		while true do
			task.wait(Config.Zombie.AITick)
			local ok, err = pcall(aiStep)
			if not ok then
				warn("[ZombieService] erreur IA : " .. tostring(err))
			end
		end
	end)
end

return ZombieService
