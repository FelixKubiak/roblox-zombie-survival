--[[
	HUD : interface du joueur, construite par code.
	Elle ne fait que LIRE l'état répliqué par le serveur :
	  - attributs de ReplicatedStorage : Phase, Wave, ZombiesLeft, PhaseEndsAt, WavesCleared, BestWaves
	  - attributs de chaque Player : State, Kills, DownEndsAt, ReviveProgress
	Elle ne décide jamais de rien : aucune triche possible côté interface.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STATE_TEXT = { Alive = "en vie", Down = "À TERRE", Dead = "mort" }
local STATE_COLOR = {
	Alive = Color3.fromRGB(130, 235, 130),
	Down = Color3.fromRGB(255, 190, 60),
	Dead = Color3.fromRGB(235, 90, 90),
}

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function label(props, parent)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.4
	return create("TextLabel", props, parent)
end

local gui = create("ScreenGui", { Name = "HUD", ResetOnSpawn = false }, playerGui)

-- Haut : vague + information
local waveLabel = label({
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(500, 40), TextSize = 32, Text = "",
}, gui)
local infoLabel = label({
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.fromOffset(600, 28), TextSize = 20, Text = "",
}, gui)

-- Bas gauche : barre de vie
local healthBack = create("Frame", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -20),
	Size = UDim2.fromOffset(300, 26), BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	BackgroundTransparency = 0.3, BorderSizePixel = 0,
}, gui)
local healthFill = create("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(80, 200, 90), BorderSizePixel = 0,
}, healthBack)
local healthText = label({ Size = UDim2.fromScale(1, 1), TextSize = 16, Text = "" }, healthBack)

-- Haut gauche : équipe
local teamPanel = create("Frame", {
	Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(300, 100), BackgroundTransparency = 1,
}, gui)
create("UIListLayout", { Padding = UDim.new(0, 2) }, teamPanel)
local teamLabels = {}

-- Annonce de vague (grand texte qui s'efface)
local announce = label({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(700, 80), TextSize = 64, Text = "", TextTransparency = 1, TextStrokeTransparency = 1,
}, gui)

-- Voile rouge : joueur à terre
local downOverlay = create("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 0, 0),
	BackgroundTransparency = 0.7, BorderSizePixel = 0, Visible = false,
}, gui)
local downText = label({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromOffset(800, 100), TextSize = 30, Text = "",
}, downOverlay)
local reviveBack = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58),
	Size = UDim2.fromOffset(360, 16), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
}, downOverlay)
local reviveFill = create("Frame", {
	Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 210, 255), BorderSizePixel = 0,
}, reviveBack)

-- Bandeau : joueur mort
local deadBanner = label({
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30),
	Size = UDim2.fromOffset(700, 40), TextSize = 22, Text = "Vous êtes mort. La partie continue sans vous…",
	TextColor3 = STATE_COLOR.Dead, Visible = false,
}, gui)

-- Écran de défaite d'équipe
local gameOver = create("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false,
}, gui)
local gameOverText = label({
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(800, 240), TextSize = 30, Text = "",
}, gameOver)

---------------------------------------------------------------------

local function showAnnounce(text)
	announce.Text = text
	announce.TextTransparency = 0
	announce.TextStrokeTransparency = 0.4
	TweenService:Create(announce, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
end

ReplicatedStorage:GetAttributeChangedSignal("Wave"):Connect(function()
	local wave = ReplicatedStorage:GetAttribute("Wave") or 0
	if wave > 0 then
		showAnnounce("VAGUE " .. wave)
	end
end)

local function refreshTeam()
	for other, teamLabel in teamLabels do
		if not other.Parent then
			teamLabel:Destroy()
			teamLabels[other] = nil
		end
	end
	for _, other in Players:GetPlayers() do
		local teamLabel = teamLabels[other]
		if not teamLabel then
			teamLabel = label({
				Size = UDim2.new(1, 0, 0, 22), TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left, Text = "",
			}, teamPanel)
			teamLabels[other] = teamLabel
		end
		local state = other:GetAttribute("State") or "Dead"
		teamLabel.Text = string.format("%s — %s — %d kills", other.DisplayName, STATE_TEXT[state] or state, other:GetAttribute("Kills") or 0)
		teamLabel.TextColor3 = STATE_COLOR[state] or Color3.new(1, 1, 1)
	end
end

local function refreshHealth()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.MaxHealth > 0 then
		local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthFill.BackgroundColor3 = Color3.fromRGB(220 * (1 - ratio) + 60, 200 * ratio + 30, 70)
		healthText.Text = string.format("%d / %d", math.ceil(humanoid.Health), humanoid.MaxHealth)
	else
		healthFill.Size = UDim2.fromScale(0, 1)
		healthText.Text = ""
	end
end

local lastTeamRefresh = 0

RunService.Heartbeat:Connect(function()
	local now = Workspace:GetServerTimeNow()
	local phase = ReplicatedStorage:GetAttribute("Phase") or "Lobby"
	local wave = ReplicatedStorage:GetAttribute("Wave") or 0
	local endsAt = ReplicatedStorage:GetAttribute("PhaseEndsAt") or 0
	local state = player:GetAttribute("State") or "Dead"

	-- Vague + information
	if phase == "Wave" then
		waveLabel.Text = "Vague " .. wave
		infoLabel.Text = "Zombies restants : " .. (ReplicatedStorage:GetAttribute("ZombiesLeft") or 0)
	elseif phase == "Intermission" then
		if wave == 0 then
			-- Tout début de partie : aucun texte, la vague 1 arrive d'elle-même
			waveLabel.Text = ""
			infoLabel.Text = ""
		else
			waveLabel.Text = "Vague " .. wave .. " terminée"
			infoLabel.Text = string.format("Prochaine vague dans %d s", math.max(0, math.ceil(endsAt - now)))
		end
	elseif phase == "GameOver" then
		waveLabel.Text = ""
		infoLabel.Text = ""
	else
		waveLabel.Text = ""
		infoLabel.Text = "En attente de joueurs…"
	end

	-- À terre
	downOverlay.Visible = (state == "Down") and phase ~= "GameOver"
	if downOverlay.Visible then
		local remaining = math.max(0, math.ceil((player:GetAttribute("DownEndsAt") or now) - now))
		downText.Text = string.format("À TERRE !\nUn coéquipier doit rester près de vous — saignement : %d s", remaining)
		reviveFill.Size = UDim2.fromScale(player:GetAttribute("ReviveProgress") or 0, 1)
	end

	deadBanner.Visible = (state == "Dead") and phase ~= "GameOver" and phase ~= "Lobby"

	-- Défaite d'équipe
	gameOver.Visible = (phase == "GameOver")
	if gameOver.Visible then
		gameOverText.Text = string.format(
			"ÉQUIPE ÉLIMINÉE\n\nVagues survécues : %d\nRecord de la session : %d\n\nNouvelle partie dans %d s",
			ReplicatedStorage:GetAttribute("WavesCleared") or 0,
			ReplicatedStorage:GetAttribute("BestWaves") or 0,
			math.max(0, math.ceil(endsAt - now))
		)
	end

	refreshHealth()
	if os.clock() - lastTeamRefresh > 0.3 then
		lastTeamRefresh = os.clock()
		refreshTeam()
	end
end)
