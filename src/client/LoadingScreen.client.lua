-- LoadingScreen: Custom, premium glassmorphic loading screen for matchmaking transitions
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Helper function to create the beautiful loading screen GUI dynamically
local function createLoadingUI(matchMode, assignedClass)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreenGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 9999 -- Extremely high Z-index to cover default chat/hud elements
	
	-- Dark, atmospheric space/planetary background frame
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromHex("#081211") -- Ultra dark teal
	bg.BorderSizePixel = 0
	bg.Parent = screenGui
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#040b0a")), -- deep space black
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#0b1c1a")), -- dark organic teal
		ColorSequenceKeypoint.new(1, Color3.fromHex("#020706")) -- shadow teal
	})
	gradient.Rotation = 45
	gradient.Parent = bg
	
	-- Central Glassmorphic Card
	local card = Instance.new("Frame")
	card.Name = "LoadingCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0.9, 0, 0, 320)
	card.BackgroundColor3 = GameConfig.Palette.DarkTeal
	card.BackgroundTransparency = 0.25 -- Glassmorphism
	card.BorderSizePixel = 0
	card.Parent = bg
	
	local cardSizeConstraint = Instance.new("UISizeConstraint")
	cardSizeConstraint.MaxWidth = 480
	cardSizeConstraint.Parent = card
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 24)
	cardCorner.Parent = card
	
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = GameConfig.Palette.PaleTeal
	cardStroke.Thickness = 1.5
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card
	
	-- Inner layout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.Parent = card
	
	-- Header: ECOSPHERE
	local title = Instance.new("TextLabel")
	title.Name = "GameTitle"
	title.Size = UDim2.new(1, 0, 0, 36)
	title.BackgroundTransparency = 1
	title.Text = "E C O S P H E R E"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.Font = Enum.Font.Montserrat
	title.FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	title.Parent = card
	
	-- Subtitle: INITIALIZING BIOME...
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 20)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "INITIALIZING BIOME..."
	subtitle.TextColor3 = GameConfig.Palette.LimeGreen
	subtitle.TextSize = 12
	subtitle.Font = Enum.Font.Montserrat
	subtitle.FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	subtitle.Parent = card
	
	-- Mode Label (e.g. Solo Mode, Duo Mode)
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, 0, 0, 20)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = string.upper(matchMode or "ESTABLISHING CONNECTIVITY...")
	modeLabel.TextColor3 = GameConfig.Palette.Cream
	modeLabel.TextSize = 14
	modeLabel.Font = Enum.Font.Nunito
	modeLabel.Parent = card

	-- Class Display container (if assigned class is known)
	if assignedClass and GameConfig.CLASSES[assignedClass] then
		local classData = GameConfig.CLASSES[assignedClass]
		
		local classFrame = Instance.new("Frame")
		classFrame.Name = "ClassFrame"
		classFrame.Size = UDim2.new(0.85, 0, 0, 85)
		classFrame.BackgroundColor3 = classData.Color
		classFrame.BackgroundTransparency = 0.85 -- subtle tint
		classFrame.BorderSizePixel = 0
		classFrame.Parent = card
		
		local classCorner = Instance.new("UICorner")
		classCorner.CornerRadius = UDim.new(0, 14)
		classCorner.Parent = classFrame
		
		local classStroke = Instance.new("UIStroke")
		classStroke.Color = classData.Color
		classStroke.Thickness = 1
		classStroke.Transparency = 0.5
		classStroke.Parent = classFrame
		
		local classIcon = Instance.new("TextLabel")
		classIcon.Name = "Icon"
		classIcon.Size = UDim2.new(0, 48, 1, 0)
		classIcon.Position = UDim2.new(0, 16, 0, 0)
		classIcon.BackgroundTransparency = 1
		classIcon.Text = classData.Icon
		classIcon.TextSize = 32
		classIcon.Font = Enum.Font.Nunito
		classIcon.TextXAlignment = Enum.TextXAlignment.Center
		classIcon.Parent = classFrame
		
		local classTitle = Instance.new("TextLabel")
		classTitle.Name = "Title"
		classTitle.Size = UDim2.new(1, -85, 0, 24)
		classTitle.Position = UDim2.new(0, 72, 0, 8)
		classTitle.BackgroundTransparency = 1
		classTitle.Text = "YOUR ROLE: " .. string.upper(classData.DisplayName)
		classTitle.TextColor3 = classData.Color
		classTitle.TextSize = 12
		classTitle.Font = Enum.Font.Montserrat
		classTitle.FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		classTitle.TextXAlignment = Enum.TextXAlignment.Left
		classTitle.Parent = classFrame
		
		local classDesc = Instance.new("TextLabel")
		classDesc.Name = "Description"
		classDesc.Size = UDim2.new(1, -85, 0, 40)
		classDesc.Position = UDim2.new(0, 72, 0, 32)
		classDesc.BackgroundTransparency = 1
		classDesc.Text = classData.Description
		classDesc.TextColor3 = GameConfig.Palette.Cream
		classDesc.TextSize = 10
		classDesc.Font = Enum.Font.Nunito
		classDesc.TextWrapped = true
		classDesc.TextXAlignment = Enum.TextXAlignment.Left
		classDesc.TextYAlignment = Enum.TextYAlignment.Top
		classDesc.Parent = classFrame
	end
	
	-- Custom Loading Indicator (Three Pulsing Dots)
	local dotsFrame = Instance.new("Frame")
	dotsFrame.Name = "DotsFrame"
	dotsFrame.Size = UDim2.new(0, 80, 0, 20)
	dotsFrame.BackgroundTransparency = 1
	dotsFrame.Parent = card
	
	local dotsLayout = Instance.new("UIListLayout")
	dotsLayout.FillDirection = Enum.FillDirection.Horizontal
	dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	dotsLayout.Padding = UDim.new(0, 8)
	dotsLayout.Parent = dotsFrame
	
	local dots = {}
	for i = 1, 3 do
		local dot = Instance.new("Frame")
		dot.Name = "Dot_" .. i
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.BackgroundColor3 = GameConfig.Palette.PaleTeal
		dot.BorderSizePixel = 0
		dot.Parent = dotsFrame
		
		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot
		
		table.insert(dots, dot)
	end
	
	-- Start pulsing animation for dots
	task.spawn(function()
		local dotIndex = 1
		while screenGui.Parent do
			for idx, dot in ipairs(dots) do
				task.spawn(function()
					local targetScale = 1.4
					local targetColor = GameConfig.Palette.LimeGreen
					if idx == dotIndex then
						TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, 12, 0, 12),
							BackgroundColor3 = targetColor,
							BackgroundTransparency = 0
						}):Play()
					else
						TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
							Size = UDim2.new(0, 8, 0, 8),
							BackgroundColor3 = GameConfig.Palette.PaleTeal,
							BackgroundTransparency = 0.4
						}):Play()
					end
				end)
			end
			dotIndex = dotIndex % 3 + 1
			task.wait(0.3)
		end
	end)
	
	-- Gentle title glow/pulse animation
	task.spawn(function()
		while screenGui.Parent do
			TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextTransparency = 0.25
			}):Play()
			task.wait(2)
		end
	end)
	
	return screenGui
end

-- Fade in UI elements
local function fadeIn(gui)
	local bg = gui:FindFirstChild("Background")
	if not bg then return end
	
	-- Store original transparencies and set to 1 for fading
	bg.BackgroundTransparency = 1
	for _, child in ipairs(bg:GetDescendants()) do
		if child:IsA("Frame") then
			child:SetAttribute("TargetTransparency", child.BackgroundTransparency)
			child.BackgroundTransparency = 1
		elseif child:IsA("TextLabel") then
			child:SetAttribute("TargetTextTransparency", child.TextTransparency)
			child.TextTransparency = 1
		elseif child:IsA("UIStroke") then
			child:SetAttribute("TargetTransparency", child.Transparency)
			child.Transparency = 1
		end
	end
	
	gui.Parent = playerGui
	
	-- Animate fade-in
	TweenService:Create(bg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0
	}):Play()
	
	for _, child in ipairs(bg:GetDescendants()) do
		if child:IsA("Frame") then
			local target = child:GetAttribute("TargetTransparency") or 0
			TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = target
			}):Play()
		elseif child:IsA("TextLabel") then
			local target = child:GetAttribute("TargetTextTransparency") or 0
			TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = target
			}):Play()
		elseif child:IsA("UIStroke") then
			local target = child:GetAttribute("TargetTransparency") or 0
			TweenService:Create(child, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = target
			}):Play()
		end
	end
	task.wait(0.4)
end

-- Fade out UI elements and destroy
local function fadeOut(gui)
	local bg = gui:FindFirstChild("Background")
	if not bg then
		gui:Destroy()
		return
	end
	
	TweenService:Create(bg, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	}):Play()
	
	for _, child in ipairs(bg:GetDescendants()) do
		if child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1
			}):Play()
		elseif child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1
			}):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1
			}):Play()
		end
	end
	task.wait(0.65)
	gui:Destroy()
end

-- ============================================================
-- INITIALIZE ON STARTUP (Dest place / arrival logic)
local existingGui = playerGui:FindFirstChild("LoadingScreenGui")
if existingGui then
	local isMatch = (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)
	
	local bg = existingGui:FindFirstChild("Background")
	local card = bg and bg:FindFirstChild("LoadingCard")
	local subtitle = card and card:FindFirstChild("Subtitle")
	
	if isMatch then
		if subtitle then
			subtitle.Text = "SPAWNING PLAYER..."
			subtitle.TextColor3 = GameConfig.Palette.SoftGold
		end
		
		-- Wait for match server to setup and start
		Remotes.StartGameClient.OnClientEvent:Wait()
		
		if subtitle then
			subtitle.Text = "BIOME READY!"
			subtitle.TextColor3 = GameConfig.Palette.LimeGreen
		end
		
		-- Wait until the character is fully loaded as a sphere and camera is bound to prevent screen flashing
		local camera = workspace.CurrentCamera
		local startTime = tick()
		while tick() - startTime < 5 do -- 5 seconds maximum timeout
			local char = player.Character
			if char and char:FindFirstChild("PlanetGravity", true) and camera.CameraType == Enum.CameraType.Scriptable then
				break
			end
			task.wait(0.1)
		end
		
		task.wait(0.3) -- Brief visual buffer for smooth transition
	else
		if subtitle then
			subtitle.Text = "ARRIVED IN LOBBY!"
			subtitle.TextColor3 = GameConfig.Palette.LimeGreen
		end
		-- Wait for player character to load
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		task.wait(1.2) -- Let the visual assets load fully
	end
	
	fadeOut(existingGui)
end

-- ============================================================
-- LISTEN FOR OUTBOUND TELEPORT (Source place / departure logic)
Remotes.QueueUpdate.OnClientEvent:Connect(function(eventType, data)
	if eventType == "teleporting" and data then
		local matchMode = data.matchMode
		local assignedClass = data.assignedClass
		
		local gui = createLoadingUI(matchMode, assignedClass)
		fadeIn(gui)
		
		pcall(function()
			TeleportService:SetTeleportGui(gui)
		end)
	end
end)

-- Return to lobby departure logic
Remotes:WaitForChild("ReturnToLobby").OnClientEvent:Connect(function(delay)
	if not delay then delay = 10 end
	
	-- Show the loading screen 1.5 seconds before the actual teleport occurs
	task.wait(math.max(0, delay - 1.5))
	
	local gui = createLoadingUI("RETURNING TO LOBBY...", nil)
	local bg = gui:FindFirstChild("Background")
	local card = bg and bg:FindFirstChild("LoadingCard")
	local subtitle = card and card:FindFirstChild("Subtitle")
	if subtitle then
		subtitle.Text = "SYNCHRONIZING WITH LOBBY..."
		subtitle.TextColor3 = GameConfig.Palette.SoftGold
	end
	
	fadeIn(gui)
	
	pcall(function()
		TeleportService:SetTeleportGui(gui)
	end)
end)

print("[EcoSphere] LoadingScreen initialized")
