-- PlanetaryMovement: Gravity, rolling, and camera for sphere character
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

warn("[PM-DEBUG] Client Script Loaded!")

-- Handle bounce from Lobby pads
local function showClassPopup(className)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sg = playerGui:FindFirstChild("ClassPopup")
	if sg then sg:Destroy() end
	
	sg = Instance.new("ScreenGui")
	sg.Name = "ClassPopup"
	sg.IgnoreGuiInset = true
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = sg
	
	local classData = GameConfig.CLASSES[className]
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 100)
	title.Position = UDim2.new(0, 0, 0.4, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.Text = "YOU ARE: " .. string.upper(className)
	title.TextColor3 = classData.Color
	title.TextScaled = true
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.Parent = frame
	sg.Parent = playerGui
	
	task.spawn(function()
		local ts = game:GetService("TweenService")
		ts:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Back), {TextTransparency = 0, TextStrokeTransparency = 0, Position = UDim2.new(0, 0, 0.35, 0)}):Play()
		task.wait(3)
		local fade = ts:Create(title, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1, Position = UDim2.new(0, 0, 0.3, 0)})
		fade:Play()
		fade.Completed:Wait()
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
		newClass = "Empath"
	end
	
	if newClass then
		Remotes.SelectClass:FireServer(newClass)
		showClassPopup(newClass)
	end
end)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local PLANET_CENTER = GameConfig.PLANET_CENTER
local GRAVITY_STRENGTH = GameConfig.GRAVITY_STRENGTH
local ROLL_SPEED = GameConfig.ROLL_SPEED

local renderConn

local function onCharacterAdded(character)
	warn("[PM-DEBUG] CharacterAdded fired for: " .. tostring(character.Name))
	
	if renderConn then
		warn("[PM-DEBUG] Disconnecting old render connection")
		renderConn:Disconnect()
		renderConn = nil
	end

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
	local gravityForce = rootPart:WaitForChild("PlanetGravity", 0.5)
	if not gravityForce then 
		warn("[PM-DEBUG] PlanetGravity not found, resetting camera to Custom for lobby")
		_G.ClassSelected = false
		return 
	end
	
	local rollTorque = rootPart:WaitForChild("RollTorque", 0.5)
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
	local mouseDelta = Vector2.new(0, 0)
	local jumpInput = false
	local keysDown = {}
	
	UIS.InputBegan:Connect(function(input, processed)
		if UIS:GetFocusedTextBox() then return end
		keysDown[input.KeyCode] = true
		if input.KeyCode == Enum.KeyCode.Space then
			jumpInput = true
		end
	end)
	UIS.InputEnded:Connect(function(input, processed)
		keysDown[input.KeyCode] = nil
		if input.KeyCode == Enum.KeyCode.Space then
			jumpInput = false
		end
	end)

	local lastPaintTime = 0
	local controlActive = false

	local function activateControls()
		warn("[PM-DEBUG] Activating controls, controlActive was: " .. tostring(controlActive))
		if controlActive then return end
		controlActive = true
		camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	task.spawn(function()
		while not _G.ClassSelected do
			task.wait(0.1)
		end
		warn("[PM-DEBUG] Class selected, calling activateControls")
		activateControls()
	end)

	-- Fallback: if color already changed
	task.delay(1, function()
		if rootPart.Color ~= Color3.fromRGB(200, 200, 200) then
			warn("[PM-DEBUG] Fallback activated - class already selected")
			_G.ClassSelected = true
			activateControls()
		end
	end)

	-- Main physics + camera loop
	renderConn = RunService.RenderStepped:Connect(function(dt)
		if not rootPart or not rootPart.Parent then return end

		local planetDir = (PLANET_CENTER - rootPart.Position)
		local distFromCenter = planetDir.Magnitude
		local gravDir = planetDir.Unit

		local mass = rootPart:GetMass()
		local antiGravity = Vector3.new(0, mass * workspace.Gravity, 0)
		gravityForce.Force = (gravDir * mass * GRAVITY_STRENGTH) + antiGravity

		local surfaceNormal = -gravDir

		if not controlActive then return end

		local delta = UIS:GetMouseDelta()
		local playerPos = rootPart.Position
		local up = surfaceNormal

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

		local inputVec = Vector3.new(0, 0, 0)
		if keysDown[Enum.KeyCode.W] then inputVec = inputVec + rotatedForward end
		if keysDown[Enum.KeyCode.S] then inputVec = inputVec - rotatedForward end
		if keysDown[Enum.KeyCode.D] then inputVec = inputVec + rotatedRight end
		if keysDown[Enum.KeyCode.A] then inputVec = inputVec - rotatedRight end

		if inputVec.Magnitude > 0.01 then
			inputVec = inputVec.Unit
			local torqueAxis = up:Cross(inputVec)
			local speedMultiplier = character:GetAttribute("ArchitectSurge") and 1.5 or 1
			rollTorque.AngularVelocity = torqueAxis * (ROLL_SPEED * speedMultiplier)
			rollTorque.MaxTorque = GameConfig.MAX_TORQUE
		else
			rollTorque.AngularVelocity = Vector3.new(0, 0, 0)
			rollTorque.MaxTorque = GameConfig.MAX_TORQUE * 0.3
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
				Remotes.PaintTrail:FireServer(rootPart.Position, surfaceNormal)
				lastPaintTime = now
			end
		end
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		humanoid.PlatformStand = true
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
