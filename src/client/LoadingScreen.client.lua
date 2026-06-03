-- LoadingScreen (StarterPlayerScripts): DEPARTURE-ONLY logic.
-- Arrival loading is handled by ReplicatedFirst/LoadingHandler.client.lua
-- which runs before any rendering occurs.
--
-- This script handles:
-- 1. Showing the loading screen when teleporting TO a match
-- 2. Showing the loading screen when returning TO the lobby

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- UI BUILDER: Creates the full glassmorphic loading card
-- ============================================================
local function createLoadingGUI(matchMode, assignedClass)
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

	-- Central Card
	local card = Instance.new("Frame")
	card.Name = "LoadingCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0.9, 0, 0, 320)
	card.BackgroundColor3 = GameConfig.Palette.DarkTeal
	card.BackgroundTransparency = 0.25
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
	subtitle.Text = "TELEPORTING..."
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
	modeLabel.Text = string.upper(matchMode or "ENTERING MATCH...")
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
		while gui.Parent do
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

	-- Title glow
	task.spawn(function()
		while gui.Parent do
			TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextTransparency = 0.25
			}):Play()
			task.wait(2)
		end
	end)

	return gui
end

-- ============================================================
-- DEPARTURE: Show loading screen INSTANTLY when teleporting to match
-- ============================================================
Remotes.QueueUpdate.OnClientEvent:Connect(function(eventType, data)
	if eventType == "teleporting" and data then
		local gui = createLoadingGUI(data.matchMode, data.assignedClass)

		-- Parent INSTANTLY — no fade-in. The screen must cover
		-- the viewport before the teleport VFX plays.
		gui.Parent = playerGui

		-- Register as the teleport GUI so it persists across place loading.
		-- This is a bonus — the ReplicatedFirst script on the destination
		-- server creates its own cover regardless of whether this persists.
		pcall(function()
			TeleportService:SetTeleportGui(gui)
		end)
	end
end)

-- ============================================================
-- DEPARTURE: Show loading screen when returning to lobby
-- ============================================================
Remotes:WaitForChild("ReturnToLobby").OnClientEvent:Connect(function(delay)
	if not delay then delay = 10 end

	-- Show 1.5 seconds before the actual teleport fires
	task.wait(math.max(0, delay - 1.5))

	local gui = createLoadingGUI("RETURNING TO LOBBY...", nil)
	local bg = gui:FindFirstChild("Background")
	local card = bg and bg:FindFirstChild("LoadingCard")
	local subtitle = card and card:FindFirstChild("Subtitle")
	if subtitle then
		subtitle.Text = "SYNCHRONIZING WITH LOBBY..."
		subtitle.TextColor3 = GameConfig.Palette.SoftGold
	end

	gui.Parent = playerGui

	pcall(function()
		TeleportService:SetTeleportGui(gui)
	end)
end)

print("[EcoSphere] LoadingScreen (departure) initialized")
