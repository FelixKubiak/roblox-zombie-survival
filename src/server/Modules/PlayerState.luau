--[[
	PlayerState : état de chaque joueur dans la partie.

	  Alive --(dégâts létaux)--> Down --(coéquipier proche pendant ReviveTime)--> Alive
	                              |
	                              +--(DownDuration écoulée)--> Dead (définitif jusqu'à la fin de la partie)

	L'état est répliqué aux clients via l'attribut "State" du Player
	(+ "DownEndsAt" et "ReviveProgress" pour l'interface).
	Tout est décidé côté serveur : le client ne fait que lire.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local PlayerState = {}

PlayerState.ALIVE = "Alive"
PlayerState.DOWN = "Down"
PlayerState.DEAD = "Dead"

local tracked = {} -- [player] = { state, connections, downEndsAt, reviveProgress }
local listeners = {}

local function getHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function setState(player, newState)
	local data = tracked[player]
	if not data or data.state == newState then
		return
	end
	local oldState = data.state
	data.state = newState
	player:SetAttribute("State", newState)
	if newState ~= PlayerState.DOWN then
		player:SetAttribute("DownEndsAt", nil)
		player:SetAttribute("ReviveProgress", 0)
	end
	for _, callback in listeners do
		task.defer(callback, player, newState, oldState)
	end
end

local function disconnectAll(data)
	for _, connection in data.connections do
		connection:Disconnect()
	end
	data.connections = {}
end

local function goDown(player, data, humanoid)
	humanoid.Health = 1
	humanoid.PlatformStand = true -- le personnage s'effondre
	data.reviveProgress = 0
	data.downEndsAt = Workspace:GetServerTimeNow() + Config.Player.DownDuration
	player:SetAttribute("DownEndsAt", data.downEndsAt)
	setState(player, PlayerState.DOWN)
end

local function die(player, data)
	if data.state == PlayerState.DEAD then
		return
	end
	setState(player, PlayerState.DEAD)
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Health = 0
	end
end

local function revive(player, data)
	setState(player, PlayerState.ALIVE)
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Health = humanoid.MaxHealth * Config.Player.ReviveHealthFraction
	end
end

---------------------------------------------------------------------
-- API publique
---------------------------------------------------------------------

-- callback(player, newState, oldState)
function PlayerState.onChanged(callback)
	table.insert(listeners, callback)
end

function PlayerState.getState(player)
	local data = tracked[player]
	return data and data.state
end

function PlayerState.register(player)
	if tracked[player] then
		return
	end
	tracked[player] = {
		state = PlayerState.DEAD, -- pas encore dans la partie
		connections = {},
		downEndsAt = 0,
		reviveProgress = 0,
	}
	player:SetAttribute("State", PlayerState.DEAD)
end

function PlayerState.unregister(player)
	local data = tracked[player]
	if not data then
		return
	end
	disconnectAll(data)
	tracked[player] = nil
end

-- À appeler quand le personnage du joueur vient d'apparaître (début de partie).
function PlayerState.spawned(player, character)
	local data = tracked[player]
	if not data then
		return
	end
	disconnectAll(data)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.Player.MaxHealth
	humanoid.Health = Config.Player.MaxHealth

	-- Pendant qu'il est à terre, la régénération naturelle ne doit pas le relever.
	table.insert(data.connections, humanoid.HealthChanged:Connect(function(health)
		if data.state == PlayerState.DOWN and health > 1 then
			humanoid.Health = 1
		end
	end))
	-- Mort « externe » (chute dans le vide, etc.) : définitive.
	table.insert(data.connections, humanoid.Died:Connect(function()
		if data.state ~= PlayerState.DEAD then
			setState(player, PlayerState.DEAD)
		end
	end))

	data.reviveProgress = 0
	data.state = nil -- force l'événement de transition
	setState(player, PlayerState.ALIVE)
end

-- Seul point d'entrée pour blesser un joueur (zombies, futurs boss, pièges...).
function PlayerState.damage(player, amount)
	local data = tracked[player]
	if not data or data.state ~= PlayerState.ALIVE then
		return
	end
	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local newHealth = humanoid.Health - amount
	if newHealth <= 1 then
		goDown(player, data, humanoid)
	else
		humanoid.Health = newHealth
	end
end

function PlayerState.countAlive()
	local count = 0
	for _, data in tracked do
		if data.state == PlayerState.ALIVE then
			count += 1
		end
	end
	return count
end

-- Joueurs encore dans la partie (en vie ou à terre) : sert à adapter la difficulté.
function PlayerState.countActive()
	local count = 0
	for _, data in tracked do
		if data.state == PlayerState.ALIVE or data.state == PlayerState.DOWN then
			count += 1
		end
	end
	return count
end

-- Cibles possibles pour les zombies : joueurs en vie uniquement.
function PlayerState.getAliveTargets()
	local targets = {}
	for player, data in tracked do
		if data.state == PlayerState.ALIVE then
			local humanoid, root = getHumanoid(player), getRoot(player)
			if humanoid and root and humanoid.Health > 0 then
				table.insert(targets, { player = player, root = root })
			end
		end
	end
	return targets
end

-- Avance les minuteurs : saignement et réanimation. `now` est injectable pour les tests.
function PlayerState.step(dt, now)
	now = now or Workspace:GetServerTimeNow()
	for player, data in tracked do
		if data.state ~= PlayerState.DOWN then
			continue
		end

		if now >= data.downEndsAt then
			die(player, data)
			continue
		end

		local helped = false
		local root = getRoot(player)
		if root then
			for other, otherData in tracked do
				if other ~= player and otherData.state == PlayerState.ALIVE then
					local otherRoot = getRoot(other)
					if otherRoot and (otherRoot.Position - root.Position).Magnitude <= Config.Player.ReviveRange then
						helped = true
						break
					end
				end
			end
		end

		if helped then
			data.reviveProgress += dt
		else
			data.reviveProgress = math.max(0, data.reviveProgress - dt)
		end

		if data.reviveProgress >= Config.Player.ReviveTime then
			revive(player, data)
		else
			player:SetAttribute("ReviveProgress", data.reviveProgress / Config.Player.ReviveTime)
		end
	end
end

function PlayerState.start()
	task.spawn(function()
		while true do
			local dt = task.wait(0.2)
			PlayerState.step(dt)
		end
	end)
end

return PlayerState
