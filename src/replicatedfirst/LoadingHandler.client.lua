-- LoadingHandler (ReplicatedFirst): Runs BEFORE any other client script.
-- Creates an opaque cover immediately so the player never sees raw game world.
-- This is the standard professional pattern for Roblox loading screens.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Detect server type IMMEDIATELY
local IS_MATCH_SERVER = (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)

-- ============================================================
-- STEP 1: Create opaque cover INSTANTLY (before any rendering)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreenGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Name = "Background"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromHex("#081211")
bg.BorderSizePixel = 0
bg.Parent = screenGui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#040b0a")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#0b1c1a")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#020706"))
})
gradient.Rotation = 45
gradient.Parent = bg

-- Simple title while modules load
local title = Instance.new("TextLabel")
title.Name = "GameTitle"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.new(0.5, 0, 0.45, 0)
title.Size = UDim2.new(0, 400, 0, 40)
title.BackgroundTransparency = 1
title.Text = "E C O S P H E R E"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 28
title.Font = Enum.Font.Montserrat
title.Parent = bg

-- Subtle pulsing dots
local dotsFrame = Instance.new("Frame")
dotsFrame.Name = "DotsFrame"
dotsFrame.AnchorPoint = Vector2.new(0.5, 0)
dotsFrame.Position = UDim2.new(0.5, 0, 0.55, 0)
dotsFrame.Size = UDim2.new(0, 80, 0, 20)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Parent = bg

local dotsLayout = Instance.new("UIListLayout")
dotsLayout.FillDirection = Enum.FillDirection.Horizontal
dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dotsLayout.Padding = UDim.new(0, 8)
dotsLayout.Parent = dotsFrame

local paleTeal = Color3.fromHex("#7EE3D0")
local limeGreen = Color3.fromHex("#A3FF78")

local dots = {}
for i = 1, 3 do
	local dot = Instance.new("Frame")
	dot.Name = "Dot_" .. i
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.BackgroundColor3 = paleTeal
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
	while screenGui.Parent do
		for idx, dot in ipairs(dots) do
			if idx == dotIndex then
				TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 12, 0, 12),
					BackgroundColor3 = limeGreen,
					BackgroundTransparency = 0
				}):Play()
			else
				TweenService:Create(dot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 8, 0, 8),
					BackgroundColor3 = paleTeal,
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
	while screenGui.Parent do
		TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
			TextTransparency = 0.25
		}):Play()
		task.wait(2)
	end
end)

-- ============================================================
-- STEP 2: Remove the default Roblox loading screen
-- ============================================================
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()

-- ============================================================
-- STEP 3: Wait for game to be ready, then fade out
-- ============================================================
local function fadeOut()
	if not screenGui or not screenGui.Parent then return end

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
	screenGui:Destroy()
end

-- Wait for Remotes to exist (they come from Rojo/ReplicatedStorage tree)
local Remotes = RS:WaitForChild("Remotes", 30)

if IS_MATCH_SERVER then
	-- MATCH SERVER: Hold the loading screen until the sphere is ready
	if Remotes then
		local startEvent = Remotes:WaitForChild("StartGameClient", 30)
		if startEvent then
			startEvent.OnClientEvent:Wait()
		end
	end

	-- Poll until sphere character + scriptable camera are confirmed
	local camera = workspace.CurrentCamera
	local timeout = tick() + 8
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

	task.wait(0.2) -- Buffer for first frame behind the screen
	fadeOut()
else
	-- LOBBY: Wait for character to load, then fade out
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	-- Check if this is a return from a match (SetTeleportGui may have persisted a GUI)
	-- Give a bit more time for assets to stream in
	local joinData = player:GetJoinData()
	local isReturning = joinData and joinData.TeleportData ~= nil

	if isReturning then
		task.wait(1.2) -- Extra time when returning from match
	else
		task.wait(0.5) -- Brief for initial lobby join
	end

	fadeOut()
end

print("[EcoSphere] LoadingHandler (ReplicatedFirst) complete")
