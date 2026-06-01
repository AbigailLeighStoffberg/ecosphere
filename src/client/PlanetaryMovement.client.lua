-- PlanetaryMovement: Gravity, rolling, and camera for sphere character
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

warn("[PM-DEBUG] Client Script Loaded!")

-- Import PlayerModule to get mobile/console control vectors
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controlModule = PlayerModule:GetControls()

-- Floating Class Assignment Card at the top of the screen
local function showClassPopup(className)
	local playerGui = player:WaitForChild("PlayerGui")
	local sg = playerGui:FindFirstChild("ClassPopup")
	if sg then sg:Destroy() end
	
	sg = Instance.new("ScreenGui")
	sg.Name = "ClassPopup"
	sg.IgnoreGuiInset = true
	
	local classData = GameConfig.CLASSES[className]
	
	-- Main floating card frame
	local cardFrame = Instance.new("Frame")
	cardFrame.Name = "CardFrame"
	cardFrame.AnchorPoint = Vector2.new(0.5, 0)
	cardFrame.Position = UDim2.new(0.5, 0, 0, -100) -- Start offscreen for slide animation
	cardFrame.Size = UDim2.new(0, 360, 0, 95)
	cardFrame.BackgroundColor3 = GameConfig.Palette.DarkTeal
	cardFrame.BackgroundTransparency = 0.15
	cardFrame.BorderSizePixel = 0
	cardFrame.Parent = sg
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = cardFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = classData.Color
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = cardFrame
	
	-- Left side: Icon Container (Circle)
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0, 56, 0, 56)
	iconContainer.Position = UDim2.new(0, 16, 0.5, 0)
	iconContainer.AnchorPoint = Vector2.new(0, 0.5)
	iconContainer.BackgroundColor3 = classData.Color
	iconContainer.BackgroundTransparency = 0.85
	iconContainer.BorderSizePixel = 0
	iconContainer.Parent = cardFrame
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0) -- Circle
	iconCorner.Parent = iconContainer
	
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = classData.Icon
	iconLabel.TextSize = 28
	iconLabel.Font = Enum.Font.Nunito
	iconLabel.Parent = iconContainer
	
	-- Right side: Text Container
	local textFrame = Instance.new("Frame")
	textFrame.Size = UDim2.new(1, -96, 1, -20)
	textFrame.Position = UDim2.new(0, 84, 0, 10)
	textFrame.BackgroundTransparency = 1
	textFrame.Parent = cardFrame
	
	local roleTitle = Instance.new("TextLabel")
	roleTitle.Size = UDim2.new(1, 0, 0, 22)
	roleTitle.BackgroundTransparency = 1
	roleTitle.Text = string.upper(classData.DisplayName)
	roleTitle.TextColor3 = classData.Color
	roleTitle.TextSize = 16
	roleTitle.Font = Enum.Font.GothamBold
	roleTitle.TextXAlignment = Enum.TextXAlignment.Left
	roleTitle.Parent = textFrame
	
	local roleDesc = Instance.new("TextLabel")
	roleDesc.Size = UDim2.new(1, 0, 1, -24)
	roleDesc.Position = UDim2.new(0, 0, 0, 24)
	roleDesc.BackgroundTransparency = 1
	roleDesc.Text = classData.Description
	roleDesc.TextColor3 = GameConfig.Palette.Cream
	roleDesc.TextSize = 11
	roleDesc.Font = Enum.Font.Nunito
	roleDesc.TextWrapped = true
	roleDesc.TextXAlignment = Enum.TextXAlignment.Left
	roleDesc.TextYAlignment = Enum.TextYAlignment.Top
	roleDesc.Parent = textFrame
	
	sg.Parent = playerGui
	
	-- Slide down and slide up animations
	task.spawn(function()
		local TweenService = game:GetService("TweenService")
		-- Slide down
		TweenService:Create(cardFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 25)
		}):Play()
		
		task.wait(4.5)
		
		-- Slide back up
		local slideUp = TweenService:Create(cardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -110)
		})
		slideUp:Play()
		slideUp.Completed:Wait()
		
		if sg and sg.Parent then sg:Destroy() end
	end)
end

Remotes:WaitForChild("StartGameClient").OnClientEvent:Connect(function(className)
	warn("[PM-DEBUG] StartGameClient received for class: " .. tostring(className))
	Remotes.SelectClass:FireServer(className)
	_G.ClassSelected = true
	showClassPopup(className)
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not _G.ClassSelected then return end
	
	local newClass = nil
	if input.KeyCode == Enum.KeyCode.One then
		newClass = "Economist"
	elseif input.KeyCode == Enum.KeyCode.Two then
		newClass = "Cultivator"
	elseif input.KeyCode == Enum.KeyCode.Three then
		newClass = "Advocate"
	end
	
	if newClass then
		Remotes.SelectClass:FireServer(newClass)
		showClassPopup(newClass)
	end
end)

local camera = Workspace.CurrentCamera

local PLANET_CENTER = GameConfig.PLANET_CENTER
local GRAVITY_STRENGTH = GameConfig.GRAVITY_STRENGTH
local ROLL_SPEED = GameConfig.ROLL_SPEED

local renderConn
local mobileControlsGui = nil

-- Clean up mobile buttons
local function removeMobileControls()
	if mobileControlsGui then
		mobileControlsGui:Destroy()
		mobileControlsGui = nil
	end
end

-- Create Mobile Screen Button for Boost
local function createMobileControls(onBoostPressed)
	removeMobileControls()
	
	local playerGui = player:WaitForChild("PlayerGui")
	mobileControlsGui = Instance.new("ScreenGui")
	mobileControlsGui.Name = "SphereMobileControls"
	mobileControlsGui.ResetOnSpawn = false
	mobileControlsGui.Parent = playerGui
	
	-- Custom Touch Boost Button (positioned next to default Roblox jump button)
	local boostBtn = Instance.new("TextButton")
	boostBtn.Name = "BoostButton"
	boostBtn.Size = UDim2.new(0, 60, 0, 60)
	boostBtn.Position = UDim2.new(1, -195, 1, -135) -- Spaced to the left of default jump button
	boostBtn.BackgroundColor3 = GameConfig.Palette.DarkTeal
	boostBtn.BackgroundTransparency = 0.2
	boostBtn.Text = "⚡"
	boostBtn.TextColor3 = GameConfig.Palette.SoftBlue
	boostBtn.TextSize = 24
	boostBtn.Font = Enum.Font.GothamBold
	boostBtn.Parent = mobileControlsGui
	
	local boostCorner = Instance.new("UICorner")
	boostCorner.CornerRadius = UDim.new(1, 0) -- Circle
	boostCorner.Parent = boostBtn
	
	local boostStroke = Instance.new("UIStroke")
	boostStroke.Color = GameConfig.Palette.SoftBlue
	boostStroke.Thickness = 2
	boostStroke.Parent = boostBtn
	
	-- Wire up touch events
	boostBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			onBoostPressed()
			boostBtn.BackgroundTransparency = 0.4
		end
	end)
	boostBtn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			boostBtn.BackgroundTransparency = 0.2
		end
	end)
	
	-- Update boost button appearance based on recharge state
	local RunService = game:GetService("RunService")
	task.spawn(function()
		while mobileControlsGui and mobileControlsGui.Parent do
			local cd = player:GetAttribute("BoostCooldown") or 0
			if tick() < cd then
				boostBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
				boostStroke.Color = Color3.fromRGB(100, 100, 100)
			else
				boostBtn.TextColor3 = GameConfig.Palette.SoftBlue
				boostStroke.Color = GameConfig.Palette.SoftBlue
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

local function onCharacterAdded(character)
	warn("[PM-DEBUG] CharacterAdded fired for: " .. tostring(character.Name))
	
	if renderConn then
		warn("[PM-DEBUG] Disconnecting old render connection")
		renderConn:Disconnect()
		renderConn = nil
	end
	removeMobileControls()

	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then
		warn("[PM-DEBUG] No HumanoidRootPart found!")
		return
	end
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		warn("[PM-DEBUG] No Humanoid found!")
		return
	end

	-- Reset camera and mouse behavior to default immediately to prevent locking/freezing
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	UIS.MouseBehavior = Enum.MouseBehavior.Default

	-- Get physics objects (will timeout for normal avatars in the lobby)
	warn("[PM-DEBUG] Waiting for PlanetGravity...")
	local gravityForce = rootPart:WaitForChild("PlanetGravity", 5)
	if not gravityForce then 
		warn("[PM-DEBUG] PlanetGravity not found, this character is not a sphere")
		return 
	end
	
	local rollTorque = rootPart:WaitForChild("RollTorque", 5)
	if not rollTorque then 
		warn("[PM-DEBUG] RollTorque not found!")
		return 
	end

	warn("[PM-DEBUG] Successfully initialized sphere physics objects")
	
	-- Enable PlatformStand ONLY for the sphere character
	humanoid.PlatformStand = true

	-- Camera setup
	local cameraDistance = 55
	local cameraHeight = 45
	local cameraSensitivity = 0.003
	local currentForward = Vector3.new(0, 0, -1)

	-- Input tracking
	local jumpInput = false
	local activeConns = {}
	
	local function cleanupConns()
		for _, conn in ipairs(activeConns) do
			if conn then conn:Disconnect() end
		end
		activeConns = {}
	end
	cleanupConns()
	
	-- Boost triggering logic
	local function triggerBoost()
		local className = character:GetAttribute("Class")
		if not className then return end
		
		local cooldown = player:GetAttribute("BoostCooldown") or 0
		if tick() < cooldown or player:GetAttribute("BoostActive") then return end
		
		-- Activate boost
		player:SetAttribute("BoostActive", true)
		
		-- Play boost sound
		local boostSound = Instance.new("Sound")
		boostSound.SoundId = "rbxassetid://9073172089" -- reusable energy hum
		boostSound.Pitch = 1.6
		boostSound.Volume = 0.8
		boostSound.Parent = rootPart
		boostSound:Play()
		game:GetService("Debris"):AddItem(boostSound, 2)
		
		task.delay(1.5, function()
			player:SetAttribute("BoostActive", false)
			player:SetAttribute("BoostCooldown", tick() + 6.0)
		end)
	end

	-- Jump triggering logic
	local function triggerJump()
		if not character:GetAttribute("Class") then return end
		jumpInput = true
	end
	
	table.insert(activeConns, UIS.InputBegan:Connect(function(input, processed)
		if UIS:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.Space then
			triggerJump()
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			triggerBoost()
		end
	end))
	
	table.insert(activeConns, UIS.InputEnded:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Space then
			jumpInput = false
		end
	end))
	
	table.insert(activeConns, UIS.JumpRequest:Connect(function()
		triggerJump()
	end))

	-- Check for initial class attribute to resolve race conditions
	local initialClass = character:GetAttribute("Class")
	if initialClass and not _G.ClassSelected then
		warn("[PM-DEBUG] Race condition prevented! Manually selecting class on load: " .. tostring(initialClass))
		Remotes.SelectClass:FireServer(initialClass)
		_G.ClassSelected = true
		showClassPopup(initialClass)
	end

	character:GetAttributeChangedSignal("Class"):Connect(function()
		local newClass = character:GetAttribute("Class")
		if newClass and not _G.ClassSelected then
			warn("[PM-DEBUG] Class attribute changed! Selecting class: " .. tostring(newClass))
			Remotes.SelectClass:FireServer(newClass)
			_G.ClassSelected = true
			showClassPopup(newClass)
		end
	end)

	-- Create mobile controls if on touch device
	if UIS.TouchEnabled then
		createMobileControls(triggerBoost)
	end

	local lastPaintTime = 0
	local controlActive = false
	local lastPaintPos = nil

	local function activateControls()
		warn("[PM-DEBUG] Activating controls, controlActive was: " .. tostring(controlActive))
		if controlActive then return end
		controlActive = true
		camera.CameraType = Enum.CameraType.Scriptable
		
		-- Only lock mouse if not on mobile/touch screen
		if not UIS.TouchEnabled then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end

	-- Main physics + camera loop
	activateControls()
	renderConn = RunService.RenderStepped:Connect(function(dt)
		if not character.Parent or not rootPart.Parent then return end

		local playerPos = rootPart.Position
		local planetDir = (PLANET_CENTER - playerPos)
		local distFromCenter = planetDir.Magnitude
		local gravDir = planetDir.Unit

		local mass = rootPart:GetMass()
		local antiGravity = Vector3.new(0, mass * workspace.Gravity, 0)
		gravityForce.Force = (gravDir * mass * GRAVITY_STRENGTH) + antiGravity

		local surfaceNormal = -gravDir
		local up = surfaceNormal

		if not controlActive then return end

		-- Keep mouse locked in center to hide the cursor on PC on every frame!
		if not UIS.TouchEnabled then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		end

		-- Camera direction updates:
		-- Touch drag camera control for mobile, MouseDelta for PC
		local delta = Vector2.new(0, 0)
		if UIS.TouchEnabled then
			-- On mobile, touch dragging updates camera angle
			-- We can read touch input from user drag movements
			local touchDelta = UIS:GetMouseDelta()
			delta = touchDelta * 0.4
		else
			delta = UIS:GetMouseDelta()
		end
		
		local yawCF = CFrame.fromAxisAngle(up, -delta.X * cameraSensitivity)
		currentForward = yawCF:VectorToWorldSpace(currentForward)
		currentForward = (currentForward - up * currentForward:Dot(up))
		if currentForward.Magnitude < 0.001 then
			currentForward = up:Cross(Vector3.new(1, 0, 0))
		end
		local rotatedForward = currentForward.Unit
		local rotatedRight = rotatedForward:Cross(up).Unit

		local camPos = playerPos - (rotatedForward * cameraDistance) + (up * cameraHeight)
		camera.CFrame = CFrame.lookAt(camPos, playerPos + (up * 4), up)

		-- Dynamic FOV based on boost
		if player:GetAttribute("BoostActive") then
			camera.FieldOfView = camera.FieldOfView + (90 - camera.FieldOfView) * (dt * 10)
		else
			camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * (dt * 10)
		end

		-- Read movement vectors from standard Roblox controller (works on WASD + mobile thumbstick)
		local moveVector = controlModule:GetMoveVector()
		local inputVec = Vector3.new(0, 0, 0)
		
		-- moveVector.Z is forward (-1) / backward (+1)
		-- moveVector.X is right (+1) / left (-1)
		if moveVector.Magnitude > 0.01 then
			inputVec = (rotatedForward * -moveVector.Z) + (rotatedRight * moveVector.X)
		end

		if inputVec.Magnitude > 0.01 then
			inputVec = inputVec.Unit
			local torqueAxis = up:Cross(inputVec)
			local speedMultiplier = character:GetAttribute("ArchitectSurge") and 1.5 or 1
			if player:GetAttribute("BoostActive") then
				speedMultiplier = speedMultiplier * 2.2
			end
			
			rollTorque.AngularVelocity = torqueAxis * (ROLL_SPEED * speedMultiplier)
			rollTorque.MaxTorque = GameConfig.MAX_TORQUE

		else
			-- Active braking: apply 0 angular velocity with moderate torque so the player can stop
			rollTorque.AngularVelocity = Vector3.new(0, 0, 0)
			rollTorque.MaxTorque = GameConfig.MAX_TORQUE * 0.35
		end

		if jumpInput then
			local surfaceDist = distFromCenter - GameConfig.PLANET_RADIUS
			if surfaceDist < 8 then
				rootPart:ApplyImpulse(surfaceNormal * mass * 120)
				jumpInput = false
			end
		end

		local now = tick()
		if now - lastPaintTime >= GameConfig.PAINT_INTERVAL then
			local surfaceDist = distFromCenter - GameConfig.PLANET_RADIUS
			if surfaceDist < 8 then
				-- Only paint if we've moved enough distance (prevents piling up at spawn)
				if not lastPaintPos or (rootPart.Position - lastPaintPos).Magnitude > 2.5 then
					Remotes.PaintTrail:FireServer(rootPart.Position, surfaceNormal)
					lastPaintTime = now
					lastPaintPos = rootPart.Position
				end
			end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		humanoid.PlatformStand = true
	end)

	-- Clean up all input connections when the character is destroyed/respawned
	table.insert(activeConns, character.Destroying:Connect(cleanupConns))
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(removeMobileControls)
