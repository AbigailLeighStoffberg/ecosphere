-- DebrisSpawner: Creates orbital debris around the planet
-- Only runs on match servers
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))

-- Skip on lobby servers
if game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then
	print("[EcoSphere] DebrisSpawner: Skipping — lobby server")
	return
end

local debrisFolder = Workspace:WaitForChild("OrbitalDebris")
local planet = Workspace:WaitForChild("PlanetBase")

local THEMES = {
	{Material = Enum.Material.Grass, Color = Color3.fromHex("#bdbc69"), Shapes = {Enum.PartType.Ball, Enum.PartType.Block}},
	{Material = Enum.Material.WoodPlanks, Color = Color3.fromHex("#925a3e"), Shapes = {Enum.PartType.Block, Enum.PartType.Cylinder}},
	{Material = Enum.Material.Glass, Color = Color3.fromHex("#3d94c0"), Shapes = {Enum.PartType.Block}},
	{Material = Enum.Material.CorrodedMetal, Color = Color3.fromHex("#829693"), Shapes = {Enum.PartType.Wedge, Enum.PartType.Cylinder}}
}

local function randomPointOnSphere(radius)
	local theta = math.random() * 2 * math.pi
	local phi = math.acos(2 * math.random() - 1)
	local x = radius * math.sin(phi) * math.cos(theta)
	local y = radius * math.sin(phi) * math.sin(theta)
	local z = radius * math.cos(phi)
	return Vector3.new(x, y, z)
end

local function spawnDebris()
	for i = 1, GameConfig.DEBRIS_COUNT do
		local orbitRadius = GameConfig.PLANET_RADIUS + GameConfig.DEBRIS_ORBIT_HEIGHT + math.random(5, 40)
		local pos = GameConfig.PLANET_CENTER + randomPointOnSphere(orbitRadius)

		local debris = Instance.new("Part")
		debris.Name = "Debris_" .. i
		local theme = THEMES[math.random(1, #THEMES)]
		debris.Shape = theme.Shapes[math.random(1, #theme.Shapes)]

		local sx = math.random(4, 16)
		local sy = math.random(4, 12)
		local sz = math.random(4, 16)
		
		-- If it's a glass solar panel, make it flat
		if theme.Material == Enum.Material.Glass then
			sy = 1
			sx = math.random(10, 20)
			sz = math.random(10, 20)
		end

		debris.Size = Vector3.new(sx, sy, sz)
		debris.Position = pos
		debris.Anchored = false
		debris.CanCollide = true
		debris.Material = theme.Material
		debris.Color = theme.Color
		debris.TopSurface = Enum.SurfaceType.Smooth
		debris.BottomSurface = Enum.SurfaceType.Smooth

		-- Bouncy physics
		debris.CustomPhysicalProperties = PhysicalProperties.new(
			0.3,  -- low density (floaty)
			0.2,  -- low friction
			0.9,  -- high elasticity (bouncy)
			1, 1
		)

		-- Gravity attachment for debris
		local att = Instance.new("Attachment")
		att.Parent = debris

		-- Pull debris toward planet (weak gravity so they float)
		local vf = Instance.new("VectorForce")
		vf.Attachment0 = att
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		local dirToCenter = (GameConfig.PLANET_CENTER - pos).Unit
		local antiGravity = Vector3.new(0, debris:GetMass() * Workspace.Gravity, 0)
		vf.Force = (dirToCenter * debris:GetMass() * 30) + antiGravity
		vf.Parent = debris

		-- Random initial rotation
		debris.CFrame = CFrame.new(pos) * CFrame.Angles(
			math.random() * math.pi * 2,
			math.random() * math.pi * 2,
			math.random() * math.pi * 2
		)

		debris.Parent = debrisFolder
	end
end

spawnDebris()
print("[EcoSphere] Orbital debris spawned:", GameConfig.DEBRIS_COUNT)
