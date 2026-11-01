--[[
	Config : toutes les valeurs d'équilibrage du jeu au même endroit.
	Module partagé serveur + client (ReplicatedStorage) : aucune valeur secrète ici.
]]

local Config = {
	Team = {
		MaxPlayers = 4,
	},

	Map = {
		Center = Vector3.new(0, 0, 0),
		GroundY = 0, -- hauteur du sol (dessus de la Baseplate)
	},

	Player = {
		MaxHealth = 100,
		DownDuration = 25, -- secondes avant la mort définitive quand on est à terre
		ReviveTime = 3, -- secondes de présence d'un coéquipier nécessaires pour relever
		ReviveRange = 8, -- distance (studs) à laquelle un coéquipier peut relever
		ReviveHealthFraction = 0.5, -- vie rendue après la réanimation
	},

	Weapon = {
		Name = "Pistol",
		Damage = 25,
		HeadshotMultiplier = 2,
		Range = 250,
		Cooldown = 0.25,
	},

	Zombie = {
		BaseHealth = 60,
		HealthPerWave = 12,
		BaseSpeed = 10,
		SpeedPerWave = 0.35,
		MaxSpeed = 14,
		Damage = 8,
		AttackRange = 5,
		AttackCooldown = 1.5,
		AITick = 0.2, -- période de mise à jour de l'IA (secondes)
	},

	Waves = {
		FirstWaveDelay = 6,
		Intermission = 10,
		BaseCount = 4, -- zombies de la vague 1 en solo
		CountPerWave = 2, -- zombies supplémentaires par vague
		TeamScaling = 0.6, -- +60 % de zombies par joueur supplémentaire
		MaxAlive = 25, -- plafond de zombies simultanés (performances)
		SpawnInterval = 0.7,
		SpawnRadius = 80,
	},

	GameOver = {
		ResultDuration = 10, -- durée de l'écran de défaite avant la nouvelle partie
	},
}

return Config
