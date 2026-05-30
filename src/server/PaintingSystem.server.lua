-- PaintingSystem: Server-side paint trail and coverage tracking
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local paintFolder = Workspace:WaitForChild("PaintTrails")
local planet = Workspace:WaitForChild("PlanetBase")

-- Player class assignments
local playerClasses = {} -- [player] = className
local playerPowerups = {} -- [player] = endTime

-- Coverage tracking via spherical grid
-- Each cell in the grid stores the class that painted it
local RES = GameConfig.GRID_RESOLUTION
local coverageGrid = {} -- [thetaIndex][phiIndex] = className or nil
for t = 1, RES do
	coverageGrid[t] = {}
end

-- Convert world position to grid cell
local function posToGrid(worldPos)
	local dir = (worldPos - GameConfig.PLANET_CENTER).Unit
	local theta = math.atan2(dir.Z, dir.X) + math.pi -- [0, 2pi]
	local phi = math.acos(math.clamp(dir.Y, -1, 1))  -- [0, pi]

	local tIdx = math.clamp(math.floor(theta / (2 * math.pi) * RES) + 1, 1, RES)
	local pIdx = math.clamp(math.floor(phi / math.pi * RES) + 1, 1, RES)
	return tIdx, pIdx
end

-- Calculate coverage percentages
local function getCoverage()
	local counts = { Economist = 0, Cultivator = 0, Advocate = 0 }
	local totalCells = RES * RES

	for t = 1, RES do
		for p = 1, RES do
			local cls = coverageGrid[t][p]
			if cls and counts[cls] ~= nil then
				counts[cls] = counts[cls] + 1
			end
		end
	end

	-- Each class has ~1/3 of the sphere as their target area
	-- But we want any painting to count, so percentage is out of total
	local targetCells = totalCells / 3
	return {
		Economist = math.min(counts.Economist / targetCells, 1),
		Cultivator = math.min(counts.Cultivator / targetCells, 1),
		Advocate = math.min(counts.Advocate / targetCells, 1),
	}
end

-- Class selection
Remotes.SelectClass.OnServerEvent:Connect(function(player, className)
	if GameConfig.CLASSES[className] then
		playerClasses[player] = className

		-- Recolor the player's ball
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local shell = char:FindFirstChild("VisualShell") or root
				shell.Color = GameConfig.CLASSES[className].Color
				shell.Material = Enum.Material.Glass
				shell.Transparency = 0.5
				
				-- Set attribute for client visuals
				char:SetAttribute("Class", className)
				
				-- Clean up old core
				local oldCore = char:FindFirstChild("CoreModel")
				if oldCore then oldCore:Destroy() end

				-- Create core model
				local coreModel = Instance.new("Model")
				coreModel.Name = "CoreModel"
				coreModel.Parent = char

				local classColor = GameConfig.CLASSES[className].Color

				if className == "Economist" then
					-- Spinning golden Diamond
					local coreBase = Instance.new("Part")
					coreBase.Name = "CoreBase"
					coreBase.Size = Vector3.new(2.5, 2.5, 2.5)
					coreBase.Color = classColor
					coreBase.Material = Enum.Material.Metal
					coreBase.CanCollide = false
					coreBase.Massless = true
					
					local mesh = Instance.new("SpecialMesh")
					mesh.MeshType = Enum.MeshType.FileMesh
					mesh.MeshId = "rbxassetid://97564601"
					mesh.Scale = Vector3.new(1.8, 1.8, 1.8)
					mesh.Parent = coreBase
					
					coreBase.Parent = coreModel

					local weld = Instance.new("Weld")
					weld.Name = "CoreWeld"
					weld.Part0 = root
					weld.Part1 = coreBase
					weld.C0 = CFrame.new(0, 0, 0)
					weld.C1 = CFrame.new(0, 0, 0)
					weld.Parent = coreBase

				elseif className == "Cultivator" then
					-- Glowing green Cylinder (seed)
					local coreBase = Instance.new("Part")
					coreBase.Name = "CoreBase"
					coreBase.Shape = Enum.PartType.Cylinder
					coreBase.Size = Vector3.new(2.2, 1.6, 1.6)
					coreBase.Color = classColor
					coreBase.Material = Enum.Material.Neon
					coreBase.CanCollide = false
					coreBase.Massless = true
					coreBase.Parent = coreModel

					local weld = Instance.new("Weld")
					weld.Name = "CoreWeld"
					weld.Part0 = root
					weld.Part1 = coreBase
					weld.C0 = CFrame.Angles(0, 0, math.rad(90))
					weld.C1 = CFrame.new(0, 0, 0)
					weld.Parent = coreBase

				elseif className == "Advocate" then
					-- Pulsating magenta Sphere + Intersecting Rings
					local coreBase = Instance.new("Part")
					coreBase.Name = "CoreBase"
					coreBase.Shape = Enum.PartType.Ball
					coreBase.Size = Vector3.new(1.5, 1.5, 1.5)
					coreBase.Color = classColor
					coreBase.Material = Enum.Material.Neon
					coreBase.CanCollide = false
					coreBase.Massless = true
					coreBase.Parent = coreModel

					local weld = Instance.new("Weld")
					weld.Name = "CoreWeld"
					weld.Part0 = root
					weld.Part1 = coreBase
					weld.C0 = CFrame.new(0, 0, 0)
					weld.C1 = CFrame.new(0, 0, 0)
					weld.Parent = coreBase

					-- Intersecting Ring 1
					local ring1 = Instance.new("Part")
					ring1.Name = "Ring1"
					ring1.Shape = Enum.PartType.Cylinder
					ring1.Size = Vector3.new(0.35, 2.6, 2.6)
					ring1.Color = classColor
					ring1.Material = Enum.Material.Neon
					ring1.CanCollide = false
					ring1.Massless = true
					ring1.Parent = coreModel

					local w1 = Instance.new("WeldConstraint")
					w1.Part0 = coreBase
					w1.Part1 = ring1
					ring1.CFrame = coreBase.CFrame * CFrame.Angles(math.rad(45), 0, 0)
					w1.Parent = ring1

					-- Intersecting Ring 2
					local ring2 = Instance.new("Part")
					ring2.Name = "Ring2"
					ring2.Shape = Enum.PartType.Cylinder
					ring2.Size = Vector3.new(0.35, 2.6, 2.6)
					ring2.Color = classColor
					ring2.Material = Enum.Material.Neon
					ring2.CanCollide = false
					ring2.Massless = true
					ring2.Parent = coreModel

					local w2 = Instance.new("WeldConstraint")
					w2.Part0 = coreBase
					w2.Part1 = ring2
					ring2.CFrame = coreBase.CFrame * CFrame.Angles(math.rad(-45), 0, 0)
					w2.Parent = ring2
				end
			end
		end
		print("[EcoSphere]", player.DisplayName, "selected class:", className)
	end
end)

-- Paint trail request
Remotes.PaintTrail.OnServerEvent:Connect(function(player, position, normal)
	local className = playerClasses[player]
	if not className then return end

	local classData = GameConfig.CLASSES[className]
	if not classData then return end

	-- Check if player has powerup active
	local paintSize = GameConfig.PAINT_SIZE_DEFAULT
	if playerPowerups[player] and tick() < playerPowerups[player] then
		paintSize = GameConfig.PAINT_SIZE_POWERUP
	end
	
	-- Architect's Surge perk
	local char = player.Character
	if char and char:GetAttribute("ArchitectSurge") then
		paintSize = paintSize * 3
	end

	-- Validate position is near planet surface
	local dist = (position - GameConfig.PLANET_CENTER).Magnitude
	if dist > GameConfig.PLANET_RADIUS + 20 then
		-- Painting on debris - still allow but don't track coverage
		local paintPart = Instance.new("Part")
		paintPart.Name = "DebrisPaint"
		paintPart.Size = Vector3.new(paintSize, 0.3, paintSize)
		if className == "Economist" then
			paintPart.Material = Enum.Material.Metal
			paintPart.Color = classData.Color
			paintPart.Transparency = 0
		else
			paintPart.Material = Enum.Material.Neon
			paintPart.Color = classData.Color
		end
		paintPart.Anchored = true
		paintPart.CanCollide = false
		paintPart.CFrame = CFrame.new(position, position + normal)
		paintPart.TopSurface = Enum.SurfaceType.Smooth
		paintPart.BottomSurface = Enum.SurfaceType.Smooth
		paintPart.Parent = paintFolder
		return
	end

	-- Snap position to planet surface
	local dirFromCenter = (position - GameConfig.PLANET_CENTER).Unit
	local surfacePos = GameConfig.PLANET_CENTER + dirFromCenter * (GameConfig.PLANET_RADIUS + 0.45)

	-- Update coverage grid
	local tIdx, pIdx = posToGrid(surfacePos)
	coverageGrid[tIdx][pIdx] = className

	-- Also mark nearby cells for larger paint
	if paintSize > GameConfig.PAINT_SIZE_DEFAULT then
		for dt = -1, 1 do
			for dp = -1, 1 do
				local nt = math.clamp(tIdx + dt, 1, RES)
				local np = math.clamp(pIdx + dp, 1, RES)
				coverageGrid[nt][np] = className
			end
		end
	end

	-- Create paint visual on planet surface
	local paintPart = Instance.new("Part")
	paintPart.Name = "Paint_" .. className
	paintPart.Shape = Enum.PartType.Cylinder
	paintPart.Size = Vector3.new(0.3, paintSize, paintSize)
	if className == "Economist" then
		paintPart.Material = Enum.Material.Metal
		paintPart.Color = classData.Color
		paintPart.Transparency = 0
	else
		paintPart.Material = Enum.Material.Neon
		paintPart.Color = classData.Color
		paintPart.Transparency = 0.1
	end
	paintPart.Anchored = true
	paintPart.CanCollide = false
	paintPart.TopSurface = Enum.SurfaceType.Smooth
	paintPart.BottomSurface = Enum.SurfaceType.Smooth

	-- Orient flat against the sphere surface
	local up = dirFromCenter
	local right = up:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 0.001 then
		right = up:Cross(Vector3.new(1, 0, 0))
	end
	right = right.Unit
	local forward = right:Cross(up).Unit

	paintPart.CFrame = CFrame.fromMatrix(surfacePos, up, forward)
	paintPart.Parent = paintFolder
end)

-- Powerup activation
Remotes.PowerupActivated.OnServerEvent:Connect(function(player)
	playerPowerups[player] = tick() + GameConfig.POWERUP_DURATION
end)

-- Broadcast coverage updates periodically
task.spawn(function()
	while true do
		task.wait(0.5)
		local coverage = getCoverage()
		Remotes.UpdateProgress:FireAllClients(coverage)
	end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	playerClasses[player] = nil
	playerPowerups[player] = nil
end)

-- Expose coverage for GameManager
local module = {}
module.getCoverage = getCoverage
module.coverageGrid = coverageGrid
module.playerClasses = playerClasses

-- Store reference for GameManager
local coverageValue = Instance.new("BindableFunction")
coverageValue.Name = "GetCoverage"
coverageValue.OnInvoke = function()
	return getCoverage()
end
coverageValue.Parent = script

-- Grayscale function for fail state
local drainEvent = Instance.new("BindableEvent")
drainEvent.Name = "DrainPaint"
drainEvent.Event:Connect(function()
	for _, paintPart in ipairs(paintFolder:GetChildren()) do
		paintPart.Color = Color3.fromRGB(80, 80, 80)
		paintPart.Material = Enum.Material.SmoothPlastic
	end
end)
drainEvent.Parent = script

print("[EcoSphere] PaintingSystem initialized")