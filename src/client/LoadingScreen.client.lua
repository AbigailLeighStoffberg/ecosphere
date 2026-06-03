-- LoadingScreen: Professional loading screen for matchmaking transitions
-- Architecture: On match servers, this script creates a loading screen IMMEDIATELY
-- at startup (before any rendering), guaranteeing no lobby flash regardless of
-- whether SetTeleportGui persisted the GUI from the previous place.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Detect server type IMMEDIATELY (no WaitForChild calls yet)
local IS_MATCH_SERVER = (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)

-- ============================================================
-- STEP 1: If on a match server, create an opaque black screen INSTANTLY
-- This runs before any other client script can render the lobby.
-- ============================================================
local arrivalScreen = nil

if IS_MATCH_SERVER then
	-- Destroy any SetTeleportGui remnant to avoid duplicates
	local existing = playerGui:FindFirstChild("LoadingScreenGui")
	if existing then existing:Destroy() end

	arrivalScreen = Instance.new("ScreenGui")
	arrivalScreen.Name = "LoadingScreenGui"
	arrivalScreen.IgnoreGuiInset = true
	arrivalScreen.ResetOnSpawn = false
	arrivalScreen.DisplayOrder = 9999
	arrivalScreen.Parent = playerGui

	local blackout = Instance.new("Frame")
	blackout.Name = "Background"
	blackout.Size = UDim2.new(1, 0, 1, 0)
	blackout.BackgroundColor3 = Color3.fromHex("#081211")
	blackout.BorderSizePixel = 0
	blackout.Parent = arrivalScreen

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#040b0a")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#0b1c1a")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#020706"))
	})
	gradient.Rotation = 45
	gradient.Parent = blackout

	-- Simple "loading..." text while we wait for GameConfig
	local tempLabel = Instance.new("TextLabel")
	tempLabel.Name = "TempLabel"
	tempLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	tempLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	tempLabel.Size = UDim2.new(0, 400, 0, 40)
	tempLabel.BackgroundTransparency = 1
	tempLabel.Text = "E C O S P H E R E"
	tempLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	tempLabel.TextSize = 28
	tempLabel.Font = Enum.Font.Montserrat
	tempLabel.Parent = blackout
end

-- ============================================================
-- Now safe to do WaitForChild calls (loading screen already covers the view)
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

-- ============================================================
-- UI BUILDER: Creates the full glassmorphic loading card
-- ============================================================
local function buildCard(parent, matchMode, assignedClass)
	local card = Instance.new("Frame")
	card.Name = "LoadingCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0.9, 0, 0, 320)
	card.BackgroundColor3 = GameConfig.Palette.DarkTeal
	card.BackgroundTransparency = 0.25
	card.BorderSizePixel = 0
	card.Parent = parent

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

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.Parent = card

	-- Title
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

	-- Subtitle
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

	-- Mode label
	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, 0, 0, 20)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = string.upper(matchMode or "ESTABLISHING CONNECTIVITY...")
	modeLabel.TextColor3 = GameConfig.Palette.Cream
	modeLabel.TextSize = 14
	modeLabel.Font = Enum.Font.Nunito
	modeLabel.Parent = card

	-- Class info card
	if assignedClass and GameConfig.CLASSES[assignedClass] then
		local classData = GameConfig.CLASSES[assignedClass]

		local classFrame = Instance.new("Frame")
		classFrame.Name = "ClassFrame"
		classFrame.Size = UDim2.new(0.85, 0, 0, 85)
		classFrame.BackgroundColor3 = classData.Color
		classFrame.BackgroundTransparency = 0.85
		classFrame.BorderSizePixel = 0
		classFrame.Parent = card

		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 14)
		cc.Parent = classFrame

		local cs = Instance.new("UIStroke")
		cs.Color = classData.Color
		cs.Thickness = 1
		cs.Transparency = 0.5
		cs.Parent = classFrame

		local classIcon = Instance.new("TextLabel")
		classIcon.Size = UDim2.new(0, 48, 1, 0)
		classIcon.Position = UDim2.new(0, 16, 0, 0)
		classIcon.BackgroundTransparency = 1
		classIcon.Text = classData.Icon
		classIcon.TextSize = 32
		classIcon.Font = Enum.Font.Nunito
		classIcon.TextXAlignment = Enum.TextXAlignment.Center
		classIcon.Parent = classFrame

		local classTitle = Instance.new("TextLabel")
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

	-- Pulsing dots
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

	-- Animate dots
	task.spawn(function()
		local dotIndex = 1
		while card.Parent do
			for idx, dot in ipairs(dots) do
				if idx == dotIndex then
					TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 12, 0, 12),
						BackgroundColor3 = GameConfig.Palette.LimeGreen,
						BackgroundTransparency = 0
					}):Play()
				else
					TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(0, 8, 0, 8),
						BackgroundColor3 = GameConfig.Palette.PaleTeal,
						BackgroundTransparency = 0.4
					}):Play()
				end
			end
			dotIndex = dotIndex % 3 + 1
			task.wait(0.3)
		end
	end)

	-- Gentle title glow
	task.spawn(function()
		while card.Parent do
			TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextTransparency = 0.25
			}):Play()
			task.wait(2)
		end
	end)

	return card, subtitle
end

-- ============================================================
-- FADE OUT: Smoothly dismiss the loading screen
-- ============================================================
local function fadeOut(gui)
	if not gui or not gui.Parent then return end

	local bg = gui:FindFirstChild("Background")
	if not bg then gui:Destroy() return end

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
-- MATCH SERVER ARRIVAL: Upgrade the instant blackout into the full card,
-- then wait for the sphere character + camera before fading out.
-- ============================================================
if IS_MATCH_SERVER and arrivalScreen then
	local bg = arrivalScreen:FindFirstChild("Background")

	-- Remove the temp label and replace with the full card
	local tempLabel = bg and bg:FindFirstChild("TempLabel")
	if tempLabel then tempLabel:Destroy() end

	local card, subtitle = buildCard(bg, nil, nil)

	-- Try to get teleport data for class info
	task.spawn(function()
		local joinData = player:GetJoinData()
		if joinData and joinData.TeleportData then
			local td = joinData.TeleportData
			local modeLabel = card:FindFirstChild("ModeLabel")
			if modeLabel and td.matchMode then
				modeLabel.Text = string.upper(td.matchMode)
			end
			local assignedClass = td.classAssignments and td.classAssignments[tostring(player.UserId)]
			if assignedClass and GameConfig.CLASSES[assignedClass] then
				-- Rebuild card with class info
				card:Destroy()
				card, subtitle = buildCard(bg, td.matchMode, assignedClass)
			end
		end
	end)

	-- Wait for the sphere to be fully set up and the camera to be scriptable
	task.spawn(function()
		if subtitle then
			subtitle.Text = "SPAWNING PLAYER..."
			subtitle.TextColor3 = GameConfig.Palette.SoftGold
		end

		-- Wait for StartGameClient (server has finished setting up the sphere)
		Remotes.StartGameClient.OnClientEvent:Wait()

		if subtitle then
			subtitle.Text = "BIOME READY!"
			subtitle.TextColor3 = GameConfig.Palette.LimeGreen
		end

		-- Now poll until the camera is actually bound to the sphere
		local camera = workspace.CurrentCamera
		local timeout = tick() + 5
		while tick() < timeout do
			local char = player.Character
			if char
				and char:FindFirstChild("PlanetGravity", true)
				and camera.CameraType == Enum.CameraType.Scriptable
			then
				break
			end
			task.wait(0.05)
		end

		task.wait(0.2) -- Tiny buffer for the first frame to render behind the screen
		fadeOut(arrivalScreen)
	end)
end

-- ============================================================
-- LOBBY ARRIVAL: If we returned from a match, handle the persisted GUI
-- ============================================================
if not IS_MATCH_SERVER then
	local existing = playerGui:FindFirstChild("LoadingScreenGui")
	if existing then
		local bg = existing:FindFirstChild("Background")
		local card = bg and bg:FindFirstChild("LoadingCard")
		local subtitle = card and card:FindFirstChild("Subtitle")

		if subtitle then
			subtitle.Text = "ARRIVED IN LOBBY!"
			subtitle.TextColor3 = GameConfig.Palette.LimeGreen
		end

		-- Wait for character to load in the lobby
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		task.wait(1.0)
		fadeOut(existing)
	end
end

-- ============================================================
-- DEPARTURE: Show loading screen INSTANTLY when teleporting
-- ============================================================
Remotes.QueueUpdate.OnClientEvent:Connect(function(eventType, data)
	if eventType == "teleporting" and data then
		-- Create the full GUI
		local gui = Instance.new("ScreenGui")
		gui.Name = "LoadingScreenGui"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 9999

		local bg = Instance.new("Frame")
		bg.Name = "Background"
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromHex("#081211")
		bg.BorderSizePixel = 0
		bg.Parent = gui

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#040b0a")),
			ColorSequenceKeypoint.new(0.5, Color3.fromHex("#0b1c1a")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#020706"))
		})
		gradient.Rotation = 45
		gradient.Parent = bg

		buildCard(bg, data.matchMode, data.assignedClass)

		-- Parent INSTANTLY — no fade-in delay
		gui.Parent = playerGui

		-- Register as the teleport GUI so it persists across place loading
		pcall(function()
			TeleportService:SetTeleportGui(gui)
		end)
	end
end)

-- Return to lobby departure
Remotes:WaitForChild("ReturnToLobby").OnClientEvent:Connect(function(delay)
	if not delay then delay = 10 end

	-- Show 1.5 seconds before the actual teleport
	task.wait(math.max(0, delay - 1.5))

	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadingScreenGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9999

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromHex("#081211")
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#040b0a")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#0b1c1a")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#020706"))
	})
	gradient.Rotation = 45
	gradient.Parent = bg

	local _, subtitle = buildCard(bg, "RETURNING TO LOBBY...", nil)
	if subtitle then
		subtitle.Text = "SYNCHRONIZING WITH LOBBY..."
		subtitle.TextColor3 = GameConfig.Palette.SoftGold
	end

	gui.Parent = playerGui

	pcall(function()
		TeleportService:SetTeleportGui(gui)
	end)
end)

print("[EcoSphere] LoadingScreen initialized")
