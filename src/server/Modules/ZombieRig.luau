--[[
	ZombieRig : construit un personnage R6 vert entièrement par code.
	Pas d'asset externe : le modèle fait partie du dépôt sous forme de code.
]]

local ZombieRig = {}

local COLORS = {
	Skin = Color3.fromRGB(104, 148, 88),
	Shirt = Color3.fromRGB(62, 78, 96),
	Pants = Color3.fromRGB(72, 58, 46),
}

local function newPart(name, size, color, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = cframe
	return part
end

local function newJoint(name, part0, part1, c0, c1)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = part0
	joint.Part1 = part1
	joint.C0 = c0
	joint.C1 = c1
	joint.Parent = part0
end

function ZombieRig.build()
	local model = Instance.new("Model")
	model.Name = "Zombie"

	local origin = CFrame.new(0, 3, 0)
	local root = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), COLORS.Skin, origin)
	root.Transparency = 1
	local torso = newPart("Torso", Vector3.new(2, 2, 1), COLORS.Shirt, origin)
	local head = newPart("Head", Vector3.new(2, 1, 1), COLORS.Skin, origin * CFrame.new(0, 1.5, 0))
	local rightArm = newPart("Right Arm", Vector3.new(1, 2, 1), COLORS.Skin, origin * CFrame.new(1.5, 0, 0))
	local leftArm = newPart("Left Arm", Vector3.new(1, 2, 1), COLORS.Skin, origin * CFrame.new(-1.5, 0, 0))
	local rightLeg = newPart("Right Leg", Vector3.new(1, 2, 1), COLORS.Pants, origin * CFrame.new(0.5, -2, 0))
	local leftLeg = newPart("Left Leg", Vector3.new(1, 2, 1), COLORS.Pants, origin * CFrame.new(-0.5, -2, 0))

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	for _, part in { root, torso, head, rightArm, leftArm, rightLeg, leftLeg } do
		part.Parent = model
	end

	-- Articulations standard d'un personnage R6
	newJoint("RootJoint", root, torso,
		CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	newJoint("Neck", torso, head,
		CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	newJoint("Right Shoulder", torso, rightArm,
		CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	newJoint("Left Shoulder", torso, leftArm,
		CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	newJoint("Right Hip", torso, rightLeg,
		CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	newJoint("Left Hip", torso, leftLeg,
		CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.DisplayName = "Zombie"
	humanoid.NameDisplayDistance = 0
	humanoid.Parent = model

	return model
end

return ZombieRig
