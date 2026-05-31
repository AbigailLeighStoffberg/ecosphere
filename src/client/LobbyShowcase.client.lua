-- LobbyShowcase: Client-side interactive class showcase pedestals, 3D rotating holograms, proximity-fade cards, and test-drive trails
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Skip if this is not the lobby place (detected by checking for Lobby folder)
local lobby = Workspace:WaitForChild("Lobby", 5)
if not lobby then
	return -- Not in the lobby place, exit
end

-- Create folder to keep showcase parts organized
local showcaseFolder = lobby:FindFirstChild("ShowcasePedestals")
if not showcaseFolder then
	showcaseFolder = Instance.new("Folder")
	showcaseFolder.Name = "ShowcasePedestals"
	showcaseFolder.Parent = lobby
else
	showcaseFolder:ClearAllChildren()
end

-- Data configuration for the three class showcase nodes arranged in a central arc on the main island
-- Placed on the East side of the circular glass floor at radius 88.13 from the lobby center (1427.6759, 634.354919)
-- spaced widely apart (Economist at -70°, Cultivator at 0°, Advocate at 50°) on clear glass zones
local classShowcases = {
	{
		ClassName = "Economist",
		TargetPosition = Vector3.new(1512.803, -180, 611.545), -- -15 degrees
		Title = "💰 THE ECONOMIST",
		Description = "Lays down a glowing network for clean, zero-waste trade. Maps out fair-trade routes and ethical supply chains.",
		Color = GameConfig.CLASSES.Economist.Color,
		Icon = GameConfig.CLASSES.Economist.Icon,
	},
	{
		ClassName = "Cultivator",
		TargetPosition = Vector3.new(1515.806, -180, 634.355), -- 0 degrees
		Title = "🌱 THE CULTIVATOR",
		Description = "Acts as a high-speed seeder. Injects bio-gels to rapidly grow forests, restore the soil, and protect the environment.",
		Color = GameConfig.CLASSES.Cultivator.Color,
		Icon = GameConfig.CLASSES.Cultivator.Icon,
	},
	{
		ClassName = "Advocate",
		TargetPosition = Vector3.new(1512.803, -180, 657.165), -- 15 degrees
		Title = "💜 THE ADVOCATE",
		Description = "Uses smart-dust to create safe zones. Maps out cultural spaces and ensures resources are shared equally for a fair community.",
		Color = GameConfig.CLASSES.Advocate.Color,
		Icon = GameConfig.CLASSES.Advocate.Icon,
	}
}

-- Find LobbyCenterBarrier to align showcase CFrames
local barrier = lobby:WaitForChild("LobbyCenterBarrier", 10)

-- Align pedestal flat against the floor normal
local function getPedestalCFrame(targetPos)
	local x, z = targetPos.X, targetPos.Z
	local y = -203 -- Fallback Y
	local up = Vector3.new(0, 1, 0)
	
	if barrier then
		local C = barrier.Position
		local N = barrier.CFrame.RightVector
		-- Solve plane equation: N.X*(x - C.X) + N.Y*(y - C.Y) + N.Z*(z - C.Z) = 0
		if math.abs(N.Y) > 0.001 then
			y = C.Y - (N.X * (x - C.X) + N.Z * (z - C.Z)) / N.Y
		end
		-- The glass floor upward normal is -N (since N points mostly down)
		up = -N.Unit
	else
		-- Fallback raycast if barrier isn't replicated yet
		local rayDir = Vector3.new(0, -60, 0)
		local rayParams = RaycastParams.new()
		local rayResult = Workspace:Raycast(targetPos, rayDir, rayParams)
		if rayResult then
			y = rayResult.Position.Y
			up = rayResult.Normal
		end
	end
	
	-- Construct matrix where UpVector is the normal 'up'
	local right = up:Cross(Vector3.new(0, 0, -1))
	if right.Magnitude < 0.001 then
		right = up:Cross(Vector3.new(1, 0, 0))
	end
	right = right.Unit
	local forward = right:Cross(up).Unit
	
	return CFrame.fromMatrix(Vector3.new(x, y, z), right, up, forward)
end

-- Temporary trail preview function for local test-drives
local function previewTrailForLocalPlayer(className, color)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Cleanup existing preview elements
	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "PreviewTrail" or child.Name == "PreviewAtt0" or child.Name == "PreviewAtt1" then
			child:Destroy()
		end
	end

	-- Attachments for trail
	local att0 = Instance.new("Attachment")
	att0.Name = "PreviewAtt0"
	att0.Position = Vector3.new(0, -2, 0)
	att0.Parent = root

	local att1 = Instance.new("Attachment")
	att1.Name = "PreviewAtt1"
	att1.Position = Vector3.new(0, 2, 0)
	att1.Parent = root

	-- Trail instance
	local trail = Instance.new("Trail")
	trail.Name = "PreviewTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 1.0
	trail.Lifetime = 0.8
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = root

	-- Extra visual juice sparks
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "PreviewTrail"
	sparks.Color = ColorSequence.new(color)
	sparks.Texture = "rbxassetid://258129767"
	sparks.Rate = 50
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0)
	})
	sparks.Lifetime = NumberRange.new(0.4, 0.7)
	sparks.Speed = NumberRange.new(4, 9)
	sparks.Parent = root

	-- Sparkle sound effect
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://8413626241" -- sparkle/beam charge sound
	sound.Volume = 0.5
	sound.Parent = root
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 2)

	-- Auto-cleanup after 8 seconds
	task.delay(8, function()
		if att0.Parent then att0:Destroy() end
		if att1.Parent then att1:Destroy() end
		if trail.Parent then trail:Destroy() end
		if sparks.Parent then sparks:Destroy() end
	end)
end

local trackedPedestals = {}

-- Construct the physical pedestals and local hologram instances
for _, data in ipairs(classShowcases) do
	local pedCFrame = getPedestalCFrame(data.TargetPosition)
	local pedModel = Instance.new("Model")
	pedModel.Name = data.ClassName .. "_Showcase"
	pedModel.Parent = showcaseFolder

	-- Base: Circular metal plate flat on ground (matching the matchmaking pads)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.6, 13, 13)
	base.Material = Enum.Material.Metal
	base.Color = Color3.fromRGB(45, 48, 52) -- Charcoal metal color matching the matchmaking pad ring
	base.Anchored = true
	base.CanCollide = true
	base.CFrame = pedCFrame * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = pedModel

	-- Core: Glowing inner neon ring (matching the matchmaking pads)
	local core = Instance.new("Part")
	core.Name = "CoreRing"
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(0.7, 12, 12)
	core.Material = Enum.Material.Neon
	core.Color = data.Color
	core.Transparency = 0.2 -- matching the matchmaking pad transparency
	core.Anchored = true
	core.CanCollide = false
	core.CFrame = pedCFrame * CFrame.Angles(0, 0, math.rad(90))
	core.Parent = pedModel

	-- Particle Emitter projecting upwards
	local projector = Instance.new("ParticleEmitter")
	projector.Name = "ProjectorBeam"
	projector.Texture = "rbxassetid://243664365"
	projector.Color = ColorSequence.new(data.Color)
	projector.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	projector.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	projector.Lifetime = NumberRange.new(1.0, 1.4)
	projector.Rate = 14
	projector.Speed = NumberRange.new(3, 5)
	projector.EmissionDirection = Enum.NormalId.Top
	projector.Parent = core

	-- Hologram Shell: Floating glass bubble
	local shell = Instance.new("Part")
	shell.Name = "HoloShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(2.2, 2.2, 2.2)
	shell.Material = Enum.Material.Glass
	shell.Color = data.Color
	shell.Transparency = 0.6
	shell.Anchored = true
	shell.CanCollide = false
	shell.CFrame = CFrame.new(pedCFrame.Position + pedCFrame.UpVector * 5.0) -- Floats slightly higher above the larger pad
	shell.Parent = pedModel

	-- Create Class-Specific spinning core geometry
	local coreGeom = {}

	if data.ClassName == "Economist" then
		-- Golden spinning diamond
		local diamond = Instance.new("Part")
		diamond.Name = "Diamond"
		diamond.Size = Vector3.new(1.6, 1.6, 1.6)
		diamond.Color = data.Color
		diamond.Material = Enum.Material.Neon
		diamond.CanCollide = false
		diamond.Anchored = true
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://97564601"
		mesh.Scale = Vector3.new(1.2, 1.2, 1.2)
		mesh.Parent = diamond
		diamond.Parent = pedModel
		
		coreGeom.BasePart = diamond

	elseif data.ClassName == "Cultivator" then
		-- Green glowing flower core
		local flowerPart = Instance.new("Part")
		flowerPart.Name = "FlowerPart"
		flowerPart.Size = Vector3.new(1.4, 1.4, 1.4)
		flowerPart.Color = data.Color
		flowerPart.Material = Enum.Material.Neon
		flowerPart.CanCollide = false
		flowerPart.Anchored = true
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://5547039023"
		mesh.Scale = Vector3.new(0.45, 0.45, 0.45)
		mesh.Parent = flowerPart
		flowerPart.Parent = pedModel
		
		coreGeom.BasePart = flowerPart

	elseif data.ClassName == "Advocate" then
		-- Magenta core sphere + intersecting rings
		local sphere = Instance.new("Part")
		sphere.Name = "Sphere"
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = Vector3.new(0.8, 0.8, 0.8)
		sphere.Color = data.Color
		sphere.Material = Enum.Material.Neon
		sphere.CanCollide = false
		sphere.Anchored = true
		sphere.Parent = pedModel

		local ring1 = Instance.new("Part")
		ring1.Name = "Ring1"
		ring1.Shape = Enum.PartType.Cylinder
		ring1.Size = Vector3.new(0.15, 1.4, 1.4)
		ring1.Color = data.Color
		ring1.Material = Enum.Material.Neon
		ring1.CanCollide = false
		ring1.Anchored = true
		ring1.Parent = pedModel

		local ring2 = Instance.new("Part")
		ring2.Name = "Ring2"
		ring2.Shape = Enum.PartType.Cylinder
		ring2.Size = Vector3.new(0.15, 1.4, 1.4)
		ring2.Color = data.Color
		ring2.Material = Enum.Material.Neon
		ring2.CanCollide = false
		ring2.Anchored = true
		ring2.Parent = pedModel

		coreGeom.BasePart = sphere
		coreGeom.Ring1 = ring1
		coreGeom.Ring2 = ring2
	end

	-- Attach wisp soul particles to the core base part
	if coreGeom.BasePart then
		local soulPart = Instance.new("ParticleEmitter")
		soulPart.Name = "SoulParticles"
		soulPart.Texture = "rbxassetid://243665306" -- Ethereal wisp texture
		soulPart.Color = ColorSequence.new(data.Color)
		soulPart.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0.2)
		})
		soulPart.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		soulPart.Lifetime = NumberRange.new(0.8, 1.2)
		soulPart.Rate = 12
		soulPart.Speed = NumberRange.new(0.4, 1.0)
		soulPart.VelocitySpread = 45
		soulPart.Acceleration = Vector3.new(0, 1.5, 0) -- Float upwards gently
		soulPart.LockedToPart = false
		soulPart.Parent = coreGeom.BasePart
	end

	-- BillboardGui Card (Must be parented to PlayerGui for buttons to be interactive!)
	local bg = Instance.new("BillboardGui")
	bg.Name = data.ClassName .. "_ShowcaseUI"
	bg.Size = UDim2.new(0, 260, 0, 160)
	bg.StudsOffset = Vector3.new(0, 3.5, 0) -- Positioned above the player's head relative to the hologram
	bg.AlwaysOnTop = true
	bg.Active = true
	bg.Enabled = false -- Start hidden
	bg.Adornee = shell
	bg.Parent = playerGui

	-- Card main Frame (handles springy size tweens)
	local frame = Instance.new("Frame")
	frame.Name = "CardFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 0, 0, 0) -- Starts at 0 size
	frame.BackgroundTransparency = 0.15
	frame.BackgroundColor3 = GameConfig.Palette.DarkTeal
	frame.BorderSizePixel = 0
	frame.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = data.Color
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	-- Card Title
	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0, 26)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = data.Title
	title.TextColor3 = data.Color
	title.TextSize = 16
	title.Font = Enum.Font.Nunito
	title.Parent = frame

	-- Card Description
	local desc = Instance.new("TextLabel")
	desc.Name = "DescLabel"
	desc.Size = UDim2.new(0.9, 0, 0, 68)
	desc.Position = UDim2.new(0.05, 0, 0, 40)
	desc.BackgroundTransparency = 1
	desc.Text = data.Description
	desc.TextColor3 = GameConfig.Palette.Cream
	desc.TextSize = 12
	desc.Font = Enum.Font.Nunito
	desc.TextWrapped = true
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.Parent = frame

	-- "Test Drive" Button
	local btn = Instance.new("TextButton")
	btn.Name = "TestDriveBtn"
	btn.Size = UDim2.new(0.8, 0, 0, 28)
	btn.Position = UDim2.new(0.1, 0, 0.72, 0)
	btn.BackgroundColor3 = data.Color
	btn.Text = "⚡ TEST DRIVE TRAIL"
	btn.TextColor3 = GameConfig.Palette.DarkTeal
	btn.TextSize = 11
	btn.Font = Enum.Font.Nunito
	btn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	-- Button bounce feedback & trigger trail preview
	btn.MouseButton1Click:Connect(function()
		-- Bounce tween animation
		local ts = TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
			Size = UDim2.new(0.72, 0, 0, 24),
			Position = UDim2.new(0.14, 0, 0.73, 0)
		})
		ts:Play()
		ts.Completed:Wait()
		TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
			Size = UDim2.new(0.8, 0, 0, 28),
			Position = UDim2.new(0.1, 0, 0.72, 0)
		}):Play()

		previewTrailForLocalPlayer(data.ClassName, data.Color)
	end)

	-- Save reference for heartbeat updates
	table.insert(trackedPedestals, {
		PedCFrame = pedCFrame,
		Shell = shell,
		BillboardGui = bg,
		CardFrame = frame,
		CoreGeom = coreGeom,
		ClassName = data.ClassName,
		Color = data.Color,
		IsNear = false,
		HologramScale = 1.0,
		RotationAngle = math.random() * 100,
	})
end

-- Perform initial state setup based on player position at load time
task.spawn(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if root then
		local charPos = root.Position
		for _, ped in ipairs(trackedPedestals) do
			local dist = (charPos - ped.PedCFrame.Position).Magnitude
			local isNear = (dist <= 16)
			
			ped.IsNear = isNear
			ped.BillboardGui.Enabled = isNear
			if isNear then
				ped.CardFrame.Size = UDim2.new(1, 0, 1, 0)
				ped.Shell.Size = Vector3.new(2.8, 2.8, 2.8)
			else
				ped.CardFrame.Size = UDim2.new(0, 0, 0, 0)
				ped.Shell.Size = Vector3.new(2.2, 2.2, 2.2)
			end
		end
	end
end)

-- Render and Proximity Loop
local activeTweens = {}
local spinSpeed = {
	Economist = 3.6,
	Cultivator = 1.0,
	Advocate = 2.0,
}

RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local charPos = root.Position
	local detectionRadius = 16

	local timeVal = tick()
	local bobOffset = math.sin(timeVal * 2.5) * 0.25

	for _, ped in ipairs(trackedPedestals) do
		-- 1. Spin and bob the core geometries inside the hologram bubble
		ped.RotationAngle = ped.RotationAngle + dt * spinSpeed[ped.ClassName]
		local angle = ped.RotationAngle
		local shell = ped.Shell
		
		-- Target CFrame with bobbing offset
		local baseCF = shell.CFrame * CFrame.new(0, bobOffset, 0)
		
		if ped.ClassName == "Economist" then
			if ped.CoreGeom.BasePart and ped.CoreGeom.BasePart.Parent then
				ped.CoreGeom.BasePart.CFrame = baseCF * CFrame.Angles(angle * 0.4, angle, 0)
			end
		elseif ped.ClassName == "Cultivator" then
			if ped.CoreGeom.BasePart and ped.CoreGeom.BasePart.Parent then
				ped.CoreGeom.BasePart.CFrame = baseCF * CFrame.Angles(0, angle * 1.2, 0)
			end
		elseif ped.ClassName == "Advocate" then
			if ped.CoreGeom.BasePart and ped.CoreGeom.BasePart.Parent then
				ped.CoreGeom.BasePart.CFrame = baseCF
			end
			if ped.CoreGeom.Ring1 and ped.CoreGeom.Ring1.Parent then
				ped.CoreGeom.Ring1.CFrame = baseCF * CFrame.Angles(angle, angle * 0.5, 0)
			end
			if ped.CoreGeom.Ring2 and ped.CoreGeom.Ring2.Parent then
				ped.CoreGeom.Ring2.CFrame = baseCF * CFrame.Angles(-angle, -angle * 0.5, 0)
			end
		end

		-- 2. Proximity Detection Check
		local dist = (charPos - ped.PedCFrame.Position).Magnitude
		local isNear = (dist <= detectionRadius)
		
		local bg = ped.BillboardGui
		local frame = ped.CardFrame
		
		if isNear and not ped.IsNear then
			ped.IsNear = true
			
			-- Cancel any ongoing tween for this frame
			if activeTweens[frame] then
				activeTweens[frame]:Cancel()
				activeTweens[frame] = nil
			end

			-- Make BillboardGui active/enabled
			bg.Enabled = true

			-- Pop in card frame with springy bounce scale
			local tween = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0)
			})
			activeTweens[frame] = tween
			tween:Play()

			-- Scale up hologram glass shell
			TweenService:Create(shell, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {
				Size = Vector3.new(2.8, 2.8, 2.8)
			}):Play()

		elseif not isNear and ped.IsNear then
			ped.IsNear = false
			
			-- Cancel any ongoing tween for this frame
			if activeTweens[frame] then
				activeTweens[frame]:Cancel()
				activeTweens[frame] = nil
			end

			-- Shrink card frame out of view
			local tween = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0)
			})
			activeTweens[frame] = tween
			
			local conn
			conn = tween.Completed:Connect(function()
				bg.Enabled = false
				activeTweens[frame] = nil
				conn:Disconnect()
			end)
			tween:Play()

			-- Scale down hologram glass shell
			TweenService:Create(shell, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = Vector3.new(2.2, 2.2, 2.2)
			}):Play()
		end
	end
end)

-- Clean up player GUI billboard objects if showcase is destroyed/shutdown
if showcaseFolder then
	showcaseFolder.AncestryChanged:Connect(function()
		if not showcaseFolder:IsDescendantOf(game) then
			for _, ped in ipairs(trackedPedestals) do
				if ped.BillboardGui then
					ped.BillboardGui:Destroy()
				end
			end
		end
	end)
end

print("[EcoSphere] LobbyShowcase initialized")
