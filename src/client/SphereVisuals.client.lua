-- SphereVisuals: Client-side game juice (squash/stretch, core animations, speed wakes, sound hum)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))

local ActiveCharacters = {}

-- Spawns a physical 3D leaf that flutters and fades out
local function spawn3DLeaf(position, velocity)
	local leaf = Instance.new("Part")
	leaf.Name = "VisualLeaf"
	leaf.Size = Vector3.new(0.7, 0.15, 1.2)
	leaf.Color = Color3.fromHex("#699254") -- Cultivator Green
	leaf.Material = Enum.Material.SmoothPlastic
	leaf.CanCollide = false
	leaf.Massless = true
	
	-- Rotate leaf slightly
	leaf.CFrame = CFrame.new(position) * CFrame.Angles(
		math.rad(math.random(-45, 45)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-45, 45))
	)
	
	-- Apply physics velocities for realistic drift
	leaf.AssemblyLinearVelocity = -velocity * 0.15 + Vector3.new(
		math.random(-5, 5),
		math.random(4, 9),
		math.random(-5, 5)
	)
	leaf.AssemblyAngularVelocity = Vector3.new(
		math.random(-15, 15),
		math.random(-15, 15),
		math.random(-15, 15)
	)
	
	leaf.Parent = Workspace
	
	-- Fade out and clean up
	task.spawn(function()
		local start = tick()
		local duration = 1.0
		while tick() - start < duration do
			local t = (tick() - start) / duration
			if not leaf or not leaf.Parent then break end
			-- Add a slight downward floating force
			leaf.AssemblyLinearVelocity = leaf.AssemblyLinearVelocity + Vector3.new(
				math.sin(tick() * 4) * 0.15,
				-0.3,
				0
			)
			leaf.Transparency = t
			task.wait(0.04)
		end
		if leaf then leaf:Destroy() end
	end)
end

-- Update loop for individual character visuals
local function updateCharacterVisuals(charData, dt)
	local character = charData.Character
	local root = charData.Root
	local shell = charData.Shell
	local className = charData.ClassName
	local sound = charData.Sound
	local shellWeld = charData.ShellWeld
	local visualMesh = charData.VisualMesh
	
	if not character.Parent or not root.Parent or not shell.Parent then
		return false
	end
	
	local velocity = root.AssemblyLinearVelocity
	local speed = velocity.Magnitude
	
	-- 1. Squash and Stretch CFrame alignment
	local targetCF
	if speed > 2 then
		targetCF = CFrame.lookAt(root.Position, root.Position + velocity)
	else
		targetCF = root.CFrame
	end
	
	-- Counteract ball's physical rotation to keep the squash/stretch aligned with movement
	local targetC0 = root.CFrame:Inverse() * targetCF
	shellWeld.C0 = shellWeld.C0:Lerp(targetC0, math.clamp(dt * 15, 0, 1))
	
	-- 2. Ricochet Impact / Squash & Stretch calculation
	local deltaV = (velocity - charData.LastVelocity)
	charData.LastVelocity = velocity
	
	-- Detect rapid speed change or direction flip (ricochet!)
	if deltaV.Magnitude > 24 and speed < charData.LastSpeed * 0.8 then
		charData.SquashAmount = math.clamp(deltaV.Magnitude * 0.015, 0.15, 0.45)
		charData.SquashTimer = 0.22 -- duration of pancaking
		charData.SquashNormal = deltaV.Unit
		
		-- Play visual bounce sound
		local bounceSound = Instance.new("Sound")
		bounceSound.SoundId = "rbxassetid://6382103525" -- bouncy boing sound
		bounceSound.Volume = 0.35 * (deltaV.Magnitude / 40)
		bounceSound.Parent = root
		bounceSound:Play()
		game:GetService("Debris"):AddItem(bounceSound, 1.2)
	end
	charData.LastSpeed = speed
	
	local scaleX, scaleY, scaleZ = 1, 1, 1
	
	if charData.SquashTimer > 0 then
		charData.SquashTimer = charData.SquashTimer - dt
		local t = charData.SquashTimer / 0.22
		local currentSquash = charData.SquashAmount * math.sin(t * math.pi)
		
		scaleZ = 1 - currentSquash
		scaleX = 1 + currentSquash * 0.5
		scaleY = 1 + currentSquash * 0.5
		
		-- Rotate weld towards impact normal during squashing
		local impactCF = CFrame.lookAt(root.Position, root.Position + charData.SquashNormal)
		local impactC0 = root.CFrame:Inverse() * impactCF
		shellWeld.C0 = shellWeld.C0:Lerp(impactC0, math.clamp(dt * 20, 0, 1))
	else
		-- Elongate based on speed (stretch along Z, squash X and Y)
		local stretch = math.clamp(speed * 0.0035, 0, 0.35)
		scaleZ = 1 + stretch
		scaleX = 1 - stretch * 0.5
		scaleY = 1 - stretch * 0.5
	end
	
	visualMesh.Scale = Vector3.new(scaleX, scaleY, scaleZ)
	
	-- 3. Core Animations (Spin and Pulsate)
	local coreModel = character:FindFirstChild("CoreModel")
	if coreModel then
		local coreBase = coreModel:FindFirstChild("CoreBase")
		if coreBase then
			local coreWeld = coreBase:FindFirstChild("CoreWeld")
			if coreWeld then
				charData.CoreAngle = (charData.CoreAngle or 0) + dt * charData.CoreSpinSpeed
				if className == "Economist" then
					-- Rapid diamond spin around multiple axes
					coreWeld.C0 = CFrame.Angles(charData.CoreAngle * 0.4, charData.CoreAngle, 0)
				elseif className == "Cultivator" then
					-- Gentle seed cylinder bobbing + slow rotation
					local bob = math.sin(tick() * 3.5) * 0.2
					coreWeld.C0 = CFrame.new(0, bob, 0) * CFrame.Angles(charData.CoreAngle * 0.25, 0, math.rad(90))
				elseif className == "Advocate" then
					-- Pulsating magenta core size + orbit ring spin
					local pulse = 1 + math.sin(tick() * 7.5) * 0.15
					coreBase.Size = Vector3.new(1.5, 1.5, 1.5) * pulse
					
					local r1 = coreModel:FindFirstChild("Ring1")
					local r2 = coreModel:FindFirstChild("Ring2")
					if r1 then r1.Size = Vector3.new(0.35 * pulse, 2.6 * pulse, 2.6 * pulse) end
					if r2 then r2.Size = Vector3.new(0.35 * pulse, 2.6 * pulse, 2.6 * pulse) end
					
					coreWeld.C0 = CFrame.Angles(0, charData.CoreAngle, 0)
				end
			end
		end
	end
	
	-- 4. Speed Emitter and Trail Wakes
	if className == "Economist" then
		local sparks = root:FindFirstChild("SparksEmitter")
		if sparks then
			if speed > 10 then
				sparks.Enabled = true
				sparks.Rate = math.clamp((speed - 10) * 1.6, 0, 110)
			else
				sparks.Enabled = false
			end
		end
	elseif className == "Cultivator" then
		if speed > 10 then
			local now = tick()
			local interval = 0.22 - math.clamp(speed * 0.0015, 0, 0.1)
			if now - charData.LastLeafTime >= interval then
				charData.LastLeafTime = now
				spawn3DLeaf(root.Position - targetCF.LookVector * 2.8 - Vector3.new(0, 1.5, 0), velocity)
			end
		end
	elseif className == "Advocate" then
		local trail = root:FindFirstChild("AdvocateTrail")
		if trail then
			if speed > 12 then
				trail.Enabled = true
				local mult = math.clamp(speed / 70, 0.25, 1)
				trail.WidthScale = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1.3 * mult),
					NumberSequenceKeypoint.new(1, 0)
				})
			else
				trail.Enabled = false
			end
		end
	end
	
	-- 5. Audio Hum adjustments
	if sound then
		if speed > 1.5 then
			sound.Volume = math.clamp((speed / 80) * 0.8, 0, 0.8)
			sound.PlaybackSpeed = 0.6 + (speed / 80) * 1.4
		else
			sound.Volume = 0
			sound.PlaybackSpeed = 0.6
		end
	end
	
	return true
end

-- Initialize the visuals structure
local function setupVisuals(character, player, root, shell, shellWeld, visualMesh, className)
	ActiveCharacters[character] = nil

	-- Disable any old class emitters
	local oldSparks = root:FindFirstChild("SparksEmitter")
	if oldSparks then oldSparks.Enabled = false end
	
	local oldTrail = root:FindFirstChild("AdvocateTrail")
	if oldTrail then oldTrail.Enabled = false end

	-- Create class specific emitters
	if className == "Economist" then
		local sparks = root:FindFirstChild("SparksEmitter")
		if not sparks then
			sparks = Instance.new("ParticleEmitter")
			sparks.Name = "SparksEmitter"
			sparks.Color = ColorSequence.new(GameConfig.CLASSES.Economist.Color)
			sparks.Texture = "rbxassetid://258129767"
			sparks.Rate = 0
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.9),
				NumberSequenceKeypoint.new(1, 0)
			})
			sparks.Lifetime = NumberRange.new(0.4, 0.7)
			sparks.Speed = NumberRange.new(6, 12)
			sparks.SpreadAngle = Vector2.new(45, 45)
			sparks.Acceleration = Vector3.new(0, -7, 0)
			sparks.Drag = 1.4
			sparks.Enabled = false
			sparks.Parent = root
		end
	elseif className == "Advocate" then
		local att0 = root:FindFirstChild("TrailAtt0")
		if not att0 then
			att0 = Instance.new("Attachment")
			att0.Name = "TrailAtt0"
			att0.Position = Vector3.new(0, -2.8, 0)
			att0.Parent = root
		end

		local att1 = root:FindFirstChild("TrailAtt1")
		if not att1 then
			att1 = Instance.new("Attachment")
			att1.Name = "TrailAtt1"
			att1.Position = Vector3.new(0, 2.8, 0)
			att1.Parent = root
		end

		local trail = root:FindFirstChild("AdvocateTrail")
		if not trail then
			trail = Instance.new("Trail")
			trail.Name = "AdvocateTrail"
			trail.Attachment0 = att0
			trail.Attachment1 = att1
			trail.Color = ColorSequence.new(Color3.fromHex("#d06a49"))
			trail.LightEmission = 1.0
			trail.Lifetime = 0.55
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(1, 1)
			})
			trail.WidthScale = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.2),
				NumberSequenceKeypoint.new(1, 0)
			})
			trail.Enabled = false
			trail.Parent = root
		end
	end

	-- Create rolling sound hum
	local hum = root:FindFirstChild("RollingHum")
	if not hum then
		hum = Instance.new("Sound")
		hum.Name = "RollingHum"
		hum.SoundId = "rbxassetid://9073172089" -- sci-fi mechanical hum
		hum.Looped = true
		hum.Volume = 0
		hum.PlaybackSpeed = 0.6
		hum.Parent = root
		hum:Play()
	end

	-- Add to active tracking
	ActiveCharacters[character] = {
		Character = character,
		Player = player,
		Root = root,
		Shell = shell,
		ShellWeld = shellWeld,
		VisualMesh = visualMesh,
		ClassName = className,
		Sound = hum,
		LastVelocity = root.AssemblyLinearVelocity,
		LastSpeed = root.AssemblyLinearVelocity.Magnitude,
		SquashTimer = 0,
		SquashAmount = 0,
		SquashNormal = Vector3.new(0, 1, 0),
		CoreAngle = math.random() * 100,
		CoreSpinSpeed = className == "Economist" and 4.2 or (className == "Advocate" and 2.5 or 1.2),
		LastLeafTime = 0
	}
end

-- Track player spawner
local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then return end

	local shell = character:WaitForChild("VisualShell", 5)
	if not shell then return end -- Normal lobby character, skip

	local shellWeld = shell:WaitForChild("ShellWeld", 5)
	local visualMesh = shell:WaitForChild("VisualMesh", 5)
	if not shellWeld or not visualMesh then return end

		-- Wait for class attribute from server
	local className = character:GetAttribute("Class")
	
	character:GetAttributeChangedSignal("Class"):Connect(function()
		local newClass = character:GetAttribute("Class")
		if newClass then
			setupVisuals(character, player, root, shell, shellWeld, visualMesh, newClass)
		end
	end)
	
	if className then
		setupVisuals(character, player, root, shell, shellWeld, visualMesh, className)
	end
end

local function monitorPlayer(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(monitorPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	monitorPlayer(player)
end

-- Render loop updater
RunService.RenderStepped:Connect(function(dt)
	for character, charData in pairs(ActiveCharacters) do
		local success, active = pcall(updateCharacterVisuals, charData, dt)
		if not success or not active then
			ActiveCharacters[character] = nil
		end
	end
end)

print("[EcoSphere] SphereVisuals initialized")